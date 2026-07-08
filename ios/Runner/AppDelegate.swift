import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Background sync (BGAppRefreshTask). The identifier must match
    // BGTaskSchedulerPermittedIdentifiers in Info.plist and
    // kIosSyncTask in lib/background/background_sync.dart.
    // iOS decides the real cadence; 30 min is the earliest we ask for.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "jp.keio.klms.klmsApp.periodicSync",
      frequency: NSNumber(value: 30 * 60)
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
