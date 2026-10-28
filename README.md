# Good Eats v2 — 그룹 맛집 결정 앱 (UI 프로토타입)

> 친구들의 취향을 모아 모두가 만족할 식당을 골라준다.
> 참조 앱: **Beli** (개인 맛집 랭킹) → v2: 개인 랭킹을 **그룹 결정**으로 확장

중간 프로젝트용 **UI 전용** 구현입니다. 화면은 모두 동작하는 것처럼 보이지만,
로그인·저장·결제·실제 추천 알고리즘은 없습니다. 모든 결과는 `mock_server/db.json`에 미리 정해 둔 가짜 데이터이며, 앱은 **GET만** 사용합니다.

## 화면 (디자인 가이드: `docs/디자인가이드.md`)
| ID | 화면 | 전환 방식 | json-server GET |
|---|---|---|---|
| A | 홈 — My Groups / Past Picks | TabBar | `/groups`, `/archived`(빈 상태) |
| B | 그룹 상세 | Navigator.push | — |
| B-5 | 그룹 설정 | showModalBottomSheet | — |
| B-6 | 친구 초대 (가짜 코드) | showDialog | — |
| C | 취향 배틀 (A vs B) | Navigator.pushReplacement (라운드마다) | `/pairs` |
| D | AI 추천 결과 | Navigator.push / pushReplacement | `/recommendations?groupId=n` |
| D-5 | 그룹에 공유 (가짜) | showDialog | — |

- **로딩/오류/빈 상태**: `lib/widgets/states.dart` 공통 위젯 (LoadingView · ErrorView · EmptyView)
- **적응형 레이아웃**: 폭 700px 이상이면 그리드/2단, 미만이면 1단 리스트 (`LayoutBuilder`)
- **Provider 등 상태관리 미사용**: 화면 변경은 `FutureBuilder`와 화면 전환으로 처리. 상태관리가 필요한 지점은 코드에 `// STATE: S1`–`S6` 주석으로 표시
- 코드 주석 `// A-1 P02`: 요소 번호 + 닐슨 원칙 번호 (발표자료 B5-4와 같음)

## 실행 방법
### 1) mock 서버 (터미널 1)
```bash
cd mock_server
npm i
npm run mock          # http://localhost:3000/groups 열리면 OK
```
### 2) Flutter 앱 (터미널 2)
```bash
flutter create . --project-name good_eats   # 플랫폼 폴더가 없을 때 한 번만
flutter pub get
flutter run -d chrome                         # 또는 windows / macos
```
Android 에뮬레이터는 localhost 대신 10.0.2.2를 씁니다:
```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:3000
```
(Android는 `android/app/src/main/AndroidManifest.xml`의 `<application>`에 `android:usesCleartextTraffic="true"` 추가)

### 상태 시연 방법
- **로딩**: 모든 화면 진입 시 0.7초 표시
- **빈 상태**: 홈의 *Past Picks* 탭 (`archived: []`)
- **오류**: mock 서버를 끄고(Ctrl+C) 화면 진입 → *Try again*

## 데모 영상
- 1분 데모: _(링크 추가)_

## docs/
- `디자인가이드.md` — 화면별 요소 번호·위젯·비즈니스 명칭·원칙·상태관리 포인트
- `원칙카드.md` · `prompt-log.md` · `셀프논증.md` · `자가평가.md`
