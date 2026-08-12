# Flutter Calculator App with GitHub Actions Auto APK Build

This is a modern, dark-themed Flutter Calculator application configured with GitHub Actions for automated Android release APK builds upon pushing to GitHub.

---

## 🚀 Features
- **Clean UI**: Modern dark theme calculator layout.
- **Math Operations**: Addition, Subtraction, Multiplication, Division, Percentage, and Positive/Negative toggling.
- **Automated CI/CD**: Built-in GitHub Actions workflow to build and upload the release APK automatically.

---

## 🛠️ How to deploy to GitHub & Build APK automatically

1. **Create a GitHub Repository**:
   - Go to [GitHub](https://github.com/new) and create a new repository named `flutter_calculator`.

2. **Push this code to GitHub**:
   ```bash
   cd flutter_calculator
   git init
   git add .
   git commit -m "Initial commit - Flutter Calculator with GitHub Actions"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/flutter_calculator.git
   git push -u origin main
   ```

3. **Download your APK from GitHub**:
   - Once pushed, go to the **Actions** tab in your GitHub repository.
   - Click on the latest workflow run named **Build Android APK**.
   - After the workflow finishes (takes ~2-3 mins), scroll down to the **Artifacts** section at the bottom.
   - Download **calculator-release-apk** zip, extract it, and install the `app-release.apk` on your Android phone!

---

## 💻 Running Locally

If you have Flutter SDK installed locally:

```bash
flutter pub get
flutter run
```
