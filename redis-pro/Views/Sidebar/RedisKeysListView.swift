//
//  RedisKeysList.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI
import Logging

struct RedisKeysListView: View {
    @EnvironmentObject var redisInstanceModel:RedisInstanceModel
    @EnvironmentObject var globalContext:GlobalContext
    @State var redisKeyModels:[RedisKeyModel] = testData()
    @State var selectedRedisKeyIndex:Int?
    @StateObject var page:Page = Page()
    @State private var renameModalVisible:Bool = false
    @State private var oldKeyIndex:Int?
    @State private var newKeyName:String = ""
    
    let logger = Logger(label: "redis-key-list-view")
    
    var selectRedisKeyModel:RedisKeyModel? {
        get {
            return (selectedRedisKeyIndex == nil || redisKeyModels.isEmpty || redisKeyModels.count <= selectedRedisKeyIndex!) ? nil : redisKeyModels[selectedRedisKeyIndex!]
        }
    }
    
    var selectRedisKey:String? {
        selectRedisKeyModel?.id
    }
    
    private var header: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 2) {
                // redis search ...
                SearchBar(keywords: $page.keywords, showFuzzy: false, placeholder: "Search keys...", action: onSearchKeyAction)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                
                // redis key operate ...
                HStack {
                    IconButton(icon: "plus", name: "Add", action: onAddAction)
                    IconButton(icon: "trash", name: "Delete", disabled: selectedRedisKeyIndex == nil, isConfirm: true,
                               confirmTitle: String(format: Helps.DELETE_KEY_CONFIRM_TITLE, selectRedisKey ?? ""),
                               confirmMessage: String(format:Helps.DELETE_KEY_CONFIRM_MESSAGE, selectRedisKey ?? ""),
                               confirmPrimaryButtonText: "Delete",
                               action: onDeleteAction)
                    
                    Spacer()
                    DatabasePicker(database: redisInstanceModel.redisModel.database, action: onRefreshAction)
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            Rectangle().frame(height: 1)
                .padding(.horizontal, 0).foregroundColor(Color.gray.opacity(0.6))
        }
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                // header area
                header
                
                // list
                List(selection: $selectedRedisKeyIndex) {
                    ForEach(redisKeyModels.indices, id:\.self) { index in
                        RedisKeyRowView(index: index, redisKeyModel: redisKeyModels[index])
                            .contextMenu {
                                Button("Rename", action: {
                                    self.oldKeyIndex = index
                                    self.renameModalVisible = true
                                })
                                MButton(text: "Delete Key", action: {try onDeleteConfirmAction(index)})
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    
                }
                .listStyle(PlainListStyle())
                .frame(minWidth:150)
                .padding(.all, 0)
                
                // footer
                SidebarFooter(page: page, pageAction: onQueryKeyPageAction)
                
            }
            .padding(0)
            .frame(minWidth:240, idealWidth: 240, maxWidth: .infinity)
            .layoutPriority(0)
            
            VStack(alignment: .leading, spacing: 0){
                if selectRedisKeyModel == nil {
                    EmptyView()
                } else {
                    RedisValueView(redisKeyModel: selectRedisKeyModel!)
                }
                Spacer()
            }
            // 这里会影响splitView 的自适应宽度, 必须加上
            .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .layoutPriority(1)
        }
        .onAppear{
            onRefreshAction()
        }
        .sheet(isPresented: $renameModalVisible) {
            ModalView("Rename", action: onRenameAction) {
                VStack(alignment:.leading, spacing: 8) {
                    FormItemText(label: "New name", placeholder: "New key name", value: $newKeyName)
                }
                .frame(minWidth:400, minHeight:50)
            }
        }
    }
    
    func onAddAction() -> Void {
        let newRedisKeyModel = RedisKeyModel(key: "NEW_KEY_\(Date().millis)", type: RedisKeyTypeEnum.STRING.rawValue, isNew: true)
        
        self.redisKeyModels.insert(newRedisKeyModel, at: 0)
        self.selectedRedisKeyIndex = 0
    }
    
    func onRenameAction() throws -> Void {
        let renameKeyModel = redisKeyModels[oldKeyIndex!]
        let r = try redisInstanceModel.getClient().rename(renameKeyModel.key, newKey: newKeyName)
        if r {
            renameKeyModel.key = newKeyName
        }
    }
    
    func onDeleteAction() throws -> Void {
        try deleteKey(selectedRedisKeyIndex!)
    }
    
    func onDeleteConfirmAction(_ index:Int) throws -> Void {
        globalContext.alertVisible = true
        globalContext.showSecondButton = true
        globalContext.primaryButtonText = "Delete"
        
        let item = redisKeyModels[index].key
        globalContext.alertTitle = String(format: Helps.DELETE_LIST_ITEM_CONFIRM_TITLE, item)
        globalContext.alertMessage = String(format:Helps.DELETE_LIST_ITEM_CONFIRM_MESSAGE, item)
        globalContext.primaryAction = {
            try deleteKey(index)
        }
    }
    
    func deleteKey(_ index:Int) throws -> Void {
        let redisKeyModel = self.redisKeyModels[index]
        let r:Int = try redisInstanceModel.getClient().del(key: redisKeyModel.key)
        logger.info("on delete redis key: \(index), r:\(r)")
        redisKeyModels.remove(at: index)
    }
    
    func onRefreshAction() -> Void {
        page.firstPage()
        try? onQueryKeyPageAction()
    }
    
    func onSearchKeyAction() throws -> Void {
        page.firstPage()
        try onQueryKeyPageAction()
    }
    
    func onQueryKeyPageAction() throws -> Void {
        if !redisInstanceModel.isConnect {
            return
        }
        let keysPage = try redisInstanceModel.getClient().pageKeys(page: page)
        logger.info("query keys page, keys: \(keysPage), page: \(String(describing: page))")
        redisKeyModels = keysPage
    }
}



func testData() -> [RedisKeyModel] {
    let redisKeys:[RedisKeyModel] = [RedisKeyModel](repeating: RedisKeyModel(key: UUID().uuidString.lowercased(), type: "string"), count: 0)
    return redisKeys
}

struct RedisKeysList_Previews: PreviewProvider {
    static var redisInstanceModel:RedisInstanceModel = RedisInstanceModel(redisModel: RedisModel())
    static var previews: some View {
        RedisKeysListView(redisKeyModels: testData())
            .environmentObject(redisInstanceModel)
    }
}
