
import OUICore
import Localize_Swift
import RxSwift
import ProgressHUD
import AlamofireNetworkActivityLogger
import FirebaseCore
import FirebaseMessaging
import GTSDK

// 个推配置
fileprivate let kGtAppId = "OAohIplDrW9cYNP4O8ljb7"
fileprivate let kGtAppKey = "VEOMbIv6Rg71jQzpqcBsx9"
fileprivate let kGtAppSecret = "2rbUkdEHXcA7dT3A2NC098"

let bussinessPort = ":10008"
let bussinessRoute = "/chat"

let adminPort = ":10008"
let adminRoute = "/chat"
let sdkAPIPort = ":10002"
let sdkAPIRoute = "/api"
let sdkWSPort = ":10001"
let sdkWSRoute = "/msg_gateway"

// TODO: 配置你的服务器地址
let defaultHost = "38.175.193.207"

let discoverPageURL = "https://www.doubao.com/"
let allowSendMsgNotFriend = "1"

let adminSeverAddrKey = "io.openim.admin.adr"
let bussinessSeverAddrKey = "io.openim.bussiness.api.adr"

// If you are using FCM, refer to the link to integrate https://firebase.google.com/docs/cloud-messaging/ios/client.

enum PushType: Int {
    case none
    case fcm
    case getui
}

fileprivate var pushType: PushType = .getui

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var orientation = UIInterfaceOrientationMask.portrait
    var window: UIWindow?
    private let _disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UINavigationBar.appearance().tintColor = .c0C1C33
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().isOpaque = true
        let backImage = UIImage(named: "common_back_icon")
        UISwitch.appearance().onTintColor = .c0089FF
        
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithDefaultBackground()
        barAppearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        UINavigationBar.appearance().standardAppearance = barAppearance
        
        ProgressHUD.animationType = .circleDotSpinFade
        ProgressHUD.colorAnimation = .systemGray2
        ProgressHUD.colorProgress = .systemGray2
        ProgressHUD.colorBackground = .clear
        ProgressHUD.colorHUD = .c0C1C33
        ProgressHUD.colorStatus = .white
        
        if #available(iOS 13.0, *) {
            let app = UINavigationBarAppearance()
            app.configureWithOpaqueBackground()
            app.titleTextAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
                NSAttributedString.Key.foregroundColor: UIColor.c0C1C33,
            ]
            app.backgroundColor = UIColor.white
            app.shadowColor = .clear
            UINavigationBar.appearance().scrollEdgeAppearance = app
            UINavigationBar.appearance().standardAppearance = app
        }
        
        // NetworkActivityLogger.shared.level = .debug
        // NetworkActivityLogger.shared.startLogging()
        
        let language = Localize.currentLanguage()
        Localize.setCurrentLanguage(language)
        
        let isIP = isValidIPAddress(defaultHost)

        let enableTLS = !isIP ? true : false
        
        let enableDomain = !isIP ? true : false
        
        let httpScheme = enableTLS ? "https://" : "http://"
        let wsScheme = enableTLS  ? "wss://" : "ws://"
        
        let appSeverAddress = httpScheme + defaultHost + (!enableDomain ? bussinessPort: bussinessRoute)
        let sdkAPIAddr = httpScheme + defaultHost + (!enableDomain ? sdkAPIPort : sdkAPIRoute)
        let sdkWSAddr = wsScheme + defaultHost + (!enableDomain ? sdkWSPort : sdkWSRoute)
        let logLevel = 5
        
        UserDefaults.standard.setValue(httpScheme + defaultHost + (!enableDomain ? adminPort : adminRoute), forKey: adminSeverAddrKey)
        UserDefaults.standard.setValue(appSeverAddress, forKey: bussinessSeverAddrKey)
        UserDefaults.standard.synchronize()
        
        IMController.shared.setup(sdkAPIAdrr: sdkAPIAddr,
                                  sdkWSAddr: sdkWSAddr,
                                  logLevel: logLevel) {
            ProgressHUD.banner("accountWarn".localized(), "accountException".localized())
            NotificationCenter.default.post(name: .init("logout"), object: nil)
        } onUserTokenInvalid: {
            ProgressHUD.banner("accountWarn".localized(), "tokenInvalid".localized())
            NotificationCenter.default.post(name: .init("logout"), object: nil)
        }
        
        AccountViewModel.getClientConfig()
        
        Task.detached { [self] in
            guard let result = await AccountViewModel.checkVersion() else { return }
            
            await updateDialog(url: result.url, version: result.version)
        }
        
        OIMApi.rotationHandler = { [weak self] o in
            self?.orientation = o
        }
        
        if pushType == .fcm {
            FirebaseApp.configure()
            Messaging.messaging().delegate = self

            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied")
                }
            }
            
            application.registerForRemoteNotifications()
        } else if pushType == .getui {
            // 个推SDK初始化
            GeTuiSdk.start(withAppId: kGtAppId, appKey: kGtAppKey, appSecret: kGtAppSecret, delegate: self)
            
            // 注册推送通知
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    print("个推推送权限已获得")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("个推推送权限被拒绝: \\(String(describing: error))")
                }
            }
        }
        
        return true
    }
    
    private func logout() {
        NotificationCenter.default.post(name: .init("logout"), object: nil)
    }
    
    func isValidIPAddress(_ ip: String) -> Bool {
        let ipv4Regex = "^(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})(\\.(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})){3}$"
        let ipv6Regex = "^([0-9a-fA-F]{1,4}:){7}([0-9a-fA-F]{1,4})$"
        
        let ipv4Predicate = NSPredicate(format: "SELF MATCHES %@", ipv4Regex)
        let ipv6Predicate = NSPredicate(format: "SELF MATCHES %@", ipv6Regex)
        
        return ipv4Predicate.evaluate(with: ip) || ipv6Predicate.evaluate(with: ip)
    }
    
    @MainActor
    private func updateDialog(url: String, version: String) {
        let infoDictionary = Bundle.main.infoDictionary
        let majorVersion = infoDictionary!["CFBundleShortVersionString"] as! String
        let minorVersion = infoDictionary!["CFBundleVersion"] as! String
        
        let appVersion = "\(majorVersion) + \(minorVersion)"
        
        guard appVersion != version else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            guard let rootViewController = window?.rootViewController else { return }
            
            rootViewController.presentAlert(title: "upgradeVersion".localizedFormat(version, appVersion), confirmTitle: "upgradeNow".localized(), cancelTitle: "upgradeLater".localized()) {
                if let u = URL(string: url) {
                    UIApplication.shared.open(u)
                }
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "taskname", expirationHandler: {
            
            if (self.backgroundTaskIdentifier != .invalid) {
                print("\(#function)")
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!);
                self.backgroundTaskIdentifier = .invalid;
            }
        });
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!);
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("\(#function)")
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientation
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if pushType == .fcm {
            Messaging.messaging().apnsToken = deviceToken
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("did Fail To Register For Remote Notifications With Error: %@", error)
    }
    
    func application(_ application: UIApplication,
                       didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // Print full message.
        print(userInfo)
        
        if pushType == .fcm {
            Messaging.messaging().appDidReceiveMessage(userInfo)
        } else if pushType == .getui {
            // 个推消息处理
            GeTuiSdk.handleRemoteNotification(userInfo)
        }
      }
}

extension AppDelegate: MessagingDelegate {
    
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")

    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
      
      if let fcmToken {
          IMController.shared.updateFCMToken(fcmToken)
      }
  }
}

// MARK: - 个推SDK代理
extension AppDelegate: GeTuiSdkDelegate {
    
    /** SDK启动成功返回cid */
    func geTuiSdkDidRegisterClient(_ clientId: String!) {
        print("个推SDK注册成功，clientId: \(clientId ?? "")")
        // 将clientId上报给OpenIM服务器
        IMController.shared.updateGetuiToken(clientId)
    }
    
    /** SDK遇到错误回调 */
    func geTuiSdkDidOccurError(_ error: Error!) {
        print("个推SDK错误: \(error.localizedDescription)")
    }
    
    /** SDK收到透传消息回调 */
    func geTuiSdkDidReceivePayloadData(_ payloadData: Data!, andTaskId taskId: String!, andMsgId msgId: String!, andOffLine offLine: Bool, fromGtAppId appId: String!) {
        
        let payloadMsg = String(data: payloadData, encoding: .utf8)
        print("个推透传消息: \(payloadMsg ?? ""), taskId: \(taskId ?? ""), msgId: \(msgId ?? "")")
    }
    
    /** SDK收到sendMessage消息回调 */
    func geTuiSdkDidSendMessage(_ messageId: String!, result: Int32) {
        print("个推发送消息结果: messageId=\(messageId ?? ""), result=\(result)")
    }
}
