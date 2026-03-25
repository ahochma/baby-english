import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.babyenglish.app',
  appName: 'Baby English',
  webDir: 'dist',
  ios: {
    contentInset: 'always',
    backgroundColor: '#ffffff',
    preferredContentMode: 'mobile',
  },
};

export default config;
