# OwnFont ✍️

OwnFont는 직접 쓴 손글씨를 디지털 폰트로 만들어,
그 폰트로 메모와 사진을 꾸미고 공유할 수 있는 iOS 앱입니다.

<a href="https://apps.apple.com/kr/app/id6762008881">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="40">
</a>

- 👤 **개인 프로젝트**
- 📅 **개발 기간** : 2026.04 ~ 진행 중
- 📱 **지원** : iOS 17.0+ / iPad 세로·가로 / iPhone 세로

</br>

## 🎯 프로젝트 목적

많은 사람들이 인스타그램에 사진을 올리며 자신만의 감성을 표현합니다.
그 감성을 더하는 방법 중 하나가 사진 위에 들어가는 **손글씨**라고 생각했습니다.

OwnFont는 누구나 자신의 손글씨를 폰트로 만들어 사진과 메모에 담을 수 있도록 하여,
획일적인 시스템 폰트 대신 **나만의 감성을 사진에 더하는 것**을 목표로 합니다.

</br>

## ✨ 주요 기능

- ✍️ **손글씨 작성** — 글자 칸을 따라 한 글자씩 직접 작성
- 🔡 **나만의 폰트 완성** — 작성한 글자로 손글씨 폰트 완성
- 📝 **내 폰트로 글쓰기** — 완성한 폰트로 문장 입력
- 🎨 **메모 · 사진 꾸미기** — 메모 작성, 사진 위 글자 꾸미기
- 📤 **인스타그램 스토리 공유** — 꾸민 결과물을 스토리로 공유

</br>

## 🛠 기술 스택

- **언어 / UI** : Swift, UIKit, SnapKit
- **비동기 / 상태 관리** : Combine
- **드로잉** : PencilKit
- **로컬 저장** : CoreData
- **의존성 관리** : Swift Package Manager

</br>

## 🏗 프로젝트 구조

기능 단위(Feature)로 모듈을 나누어 구성했습니다.

```
OwnFont/
├── Feature/
│   ├── CharacterSet/
│   ├── CharacterWriting/
│   ├── FontGeneration/
│   ├── TextEditor/
│   └── CardDecorate/
├── Common/
├── CoreData/
├── Resources/
└── Assets.xcassets/
```
