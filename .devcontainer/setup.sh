#!/bin/bash

# ۱. نصب فلاتر (اگر از قبل نبود)
if ! command -v flutter &> /dev/null
then
    git clone https://github.com/flutter/flutter.git $HOME/flutter
    export PATH="$PATH:$HOME/flutter/bin"
fi

# ۲. نصب Android SDK Command-line tools
mkdir -p $HOME/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
unzip cmdline-tools.zip -d $HOME/android-sdk/cmdline-tools
mv $HOME/android-sdk/cmdline-tools/cmdline-tools $HOME/android-sdk/cmdline-tools/latest
rm cmdline-tools.zip

# ۳. تنظیم متغیرهای محیطی (Environment Variables)
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$HOME/flutter/bin

# ۴. قبول کردن لایسنس‌های اندروید (بسیار مهم)
yes | flutter doctor --android-licenses

# ۵. بررسی نهایی
flutter doctor