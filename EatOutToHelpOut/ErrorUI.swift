import Foundation

struct ErrorUI {
    typealias ErrorUIAction = (_ actionTitle: String)->Void
    let message: String
    let title: String
    let defaultActionTitle: String
    let errorActionHandler: ErrorUIAction?
}

extension ErrorUI {

    init(error: Error, action: ErrorUIAction? = nil) {
        self.title = "Internal Error"
        self.defaultActionTitle = "OK"
        self.message = error.localizedDescription
        self.errorActionHandler = action
    }

}
