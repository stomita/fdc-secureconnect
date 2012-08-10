/**
 *
 */
global class SecureConnectInstallHandler implements InstallHandler {
  /**
   *
   */
  global void onInstall(InstallContext context) {
    if (context.previousVersion() == null) {
      SecureConnect.globalInit();
    }
  }
}