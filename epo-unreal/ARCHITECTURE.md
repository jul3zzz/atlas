# EPO pour Unreal Engine 5.8 — architecture et contrat de code

Ce document est **le contrat** que suit tout le code C++ du portage. Il décrit
les dossiers, les classes, leurs fonctions publiques et les conventions. Toute
personne (ou IA) qui ajoute un fichier doit le respecter. Si une API ci-dessous
doit changer, on modifie d'abord ce document.

La version Godot (`../epo/`) reste **la référence fonctionnelle** : chaque écran,
chaque règle de jeu et chaque modèle 3D est porté depuis le fichier GDScript du
même nom, en gardant la même logique, les mêmes valeurs et les mêmes textes.

## 1. Principe : un projet Unreal « tout en code »

Comme dans la version Godot, **tout est construit par le code au lancement** :

- **Interface** : widgets UMG créés en C++ (`WidgetTree->ConstructWidget`), sans
  Widget Blueprint.
- **Modèles 3D** : formes simples (boîte, cylindre, sphère, capsule, tore, prisme)
  générées dans des `UProceduralMeshComponent`, sans fichier de modèle.
- **Données** : les mêmes fichiers JSON que Godot, lus à l'exécution.
- **Sons et polices** : les mêmes `.wav` et `.ttf`, lus à l'exécution.
- **Niveau** : la carte vide du moteur `/Engine/Maps/Entry` ; la lumière, le ciel
  et les décors sont créés en code.

Pourquoi : le texte se lit, se compare et se corrige facilement (y compris par une
IA), et les données restent modifiables sans ouvrir l'éditeur. Les seuls fichiers
`.uasset` sont deux matériaux créés par un script Python (`Tools/setup_assets.py`) ;
s'ils manquent, le jeu se rabat sur `/Engine/BasicShapes/BasicShapeMaterial`.

## 2. Dossiers

```
epo-unreal/
├── EPO.uproject
├── Config/                     DefaultEngine.ini, DefaultGame.ini, DefaultEditor.ini
├── Source/
│   ├── EPO.Target.cs, EPOEditor.Target.cs
│   └── EPO/
│       ├── EPO.Build.cs, EPO.h, EPO.cpp        module principal
│       ├── Core/      JSON, conversion Godot→Unreal, sous-systèmes (contenu, jeu,
│       │              navigation, sons), GameInstance, GameMode, PlayerController
│       ├── UI/        style (couleurs, polices), fabrique de widgets, texte riche,
│       │              écran de base, couche racine (modales, toasts, fondu)
│       ├── Models/    générateur de maillages, matériaux, soldat, cheval,
│       │              véhicules, armes de l'atelier, scène d'aperçu
│       ├── Screens/   un fichier par écran (titre, profils, carte, époque…)
│       ├── Battle/    bataille 3D (champ, unités, projectiles, effets, ragdolls)
│       └── Workshop/  atelier d'armes et bureau d'études
├── Content/EPOData/            copie de ../epo/data et ../epo/assets (non suivie
│                               par Git, remplie par Tools/sync_from_godot.py)
└── Tools/                      sync_from_godot.py, setup_assets.py, build.ps1
```

**Données à l'exécution** (`UEPOContentSubsystem::DataRoot()`) : on cherche
d'abord `Content/EPOData/`, puis `../epo/` (dépôt de développement). Les deux ont
la même disposition : `data/*.json`, `data/history/*.json`, `data/weapons/*.json`,
`assets/audio/*.wav`, `assets/fonts/*.ttf`. Le jeu empaqueté embarque
`Content/EPOData` en fichiers libres (`DirectoriesToAlwaysStageAsNonUFS`).

## 3. Conventions

- **Préfixe `EPO`** pour tous les types : `UEPOContentSubsystem`, `AEPOBattleUnit`,
  `FEPOMeshBuilder`… Un fichier `.h/.cpp` par classe, nommé comme la classe sans
  préfixe de type (`EPOContentSubsystem.h`).
- **Export** : macro `EPO_API` sur les classes publiques.
- **Commentaires en français**, comme dans la version Godot. Noms de fonctions :
  ceux de Godot en PascalCase (`set_step` → `SetStep`, `units_for_era` →
  `UnitsForEra`).
- **Pas de Blueprint, pas de Widget Blueprint, pas d'asset Input** : tout en C++.
- **UPROPERTY** sur tout pointeur `UObject` conservé (sinon le ramasse-miettes le
  détruit). `TObjectPtr<>` pour les membres.
- **Entrées clavier/souris** : `APlayerController::IsInputKeyDown(EKeys::…)`,
  `WasInputKeyJustPressed`, `GetMousePosition`, et les événements UMG
  (`NativeOnMouseButtonDown`…). Pas d'Enhanced Input (il exige des assets).
- **Inclure ce qu'on utilise** (IWYU) : chaque `.cpp` inclut les en-têtes des types
  qu'il utilise ; `CoreMinimal.h` en tête des `.h`.

### 3.1 Espace Godot → espace Unreal (`Core/EPOConv.h`)

Godot : mètres, Y vers le haut, −Z vers l'avant, repère main droite, angles
d'Euler en ordre YXZ. Unreal : centimètres, Z vers le haut, +X vers l'avant, +Y à
droite, repère main gauche.

| Godot | Unreal |
|---|---|
| position `(x, y, z)` m | `FVector(-z, x, y) * 100` cm |
| taille de boîte `(sx, sy, sz)` m | `FVector(sz, sx, sy) * 100` cm |
| direction `(x, y, z)` | `FVector(-z, x, y)` |
| rotation Euler `(rx, ry, rz)` (YXZ) | `EPOConv::Rot(...)` (voir ci-dessous) |

`EPOConv::Rot` : on construit la matrice Godot `R = Ry(ry) · Rx(rx) · Rz(rz)`
(rotations main droite, vecteurs colonnes), puis `R_ue = M · R · Mᵀ` avec `M` la
matrice de passage ci-dessus (`M·(x,y,z) = (-z, x, y)`). La rotation Unreal est
la `FMatrix` dont les lignes sont `R_ue·(1,0,0)`, `R_ue·(0,1,0)`, `R_ue·(0,0,1)`,
convertie en `FQuat`. **Tout le code porté passe les valeurs Godot telles quelles
à ces fonctions** : on recopie les nombres du GDScript sans les convertir à la main.

```cpp
namespace EPOConv
{
	EPO_API FVector Pos(const FVector& G);            // mètres Godot -> cm Unreal
	EPO_API FVector Dir(const FVector& G);            // sans échelle
	EPO_API FVector Size(const FVector& G);           // tailles (toujours positives)
	EPO_API double Len(double Meters);                // 1 m -> 100 cm
	EPO_API FQuat Rot(const FVector& GEulerRad);      // Euler Godot (radians, YXZ)
	EPO_API FQuat RotDeg(const FVector& GEulerDeg);   // idem en degrés (fichiers JSON)
	EPO_API FTransform Xform(const FVector& GPos, const FVector& GEulerRad, const FVector& GScale = FVector::OneVector);
	EPO_API FVector ToGodot(const FVector& UePos);    // inverse de Pos (utile pour la logique portée)
}
```

**Logique de jeu** (bataille notamment) : on peut garder les calculs en espace
Godot (mètres, plan XZ) comme dans le GDScript et ne convertir qu'au moment de
placer les acteurs. C'est recommandé pour un portage fidèle.

### 3.2 JSON (`Core/EPOJson.h`)

Les données restent des objets JSON, comme les `Dictionary` de Godot.

```cpp
using FEPOObj = TSharedPtr<FJsonObject>;
using FEPOVal = TSharedPtr<FJsonValue>;
using FEPOArr = TArray<TSharedPtr<FJsonValue>>;

namespace EPOJson
{
	EPO_API FEPOVal LoadFile(const FString& Path);   // nullptr + log si erreur
	EPO_API FEPOObj Parse(const FString& Text);      // nullptr si invalide
	EPO_API FString Write(const FEPOObj& O, bool bPretty = false);
	EPO_API bool SaveFile(const FEPOObj& O, const FString& Path, bool bPretty = true);
	EPO_API FEPOObj MakeObj();

	EPO_API bool Has(const FEPOObj& O, const FString& Key);
	EPO_API FString Str(const FEPOObj& O, const FString& Key, const FString& Def = FString());
	EPO_API double Num(const FEPOObj& O, const FString& Key, double Def = 0.0);
	EPO_API int32 Int(const FEPOObj& O, const FString& Key, int32 Def = 0);
	EPO_API bool Bool(const FEPOObj& O, const FString& Key, bool Def = false);
	EPO_API FEPOObj Obj(const FEPOObj& O, const FString& Key);         // nullptr si absent
	EPO_API const FEPOArr& Arr(const FEPOObj& O, const FString& Key);  // vide si absent
	EPO_API FVector Vec3(const FEPOVal& V, const FVector& Def = FVector::ZeroVector); // [x,y,z]
	EPO_API FVector Vec3(const FEPOObj& O, const FString& Key, const FVector& Def = FVector::ZeroVector);
	EPO_API FLinearColor Color(const FString& Hex, const FLinearColor& Def = FLinearColor::White); // "#rrggbb", "rrggbb", "#rrggbbaa" (sRGB)
	EPO_API FString ValStr(const FEPOVal& V, const FString& Def = FString());
	EPO_API double ValNum(const FEPOVal& V, double Def = 0.0);
	EPO_API FEPOObj ValObj(const FEPOVal& V);
}
```

## 4. Cœur (`Core/`)

### 4.1 `UEPOGameInstance` (UGameInstance)
Classe de GameInstance du projet (déclarée dans `DefaultEngine.ini`). Rien de plus
que le point d'entrée : au `Init()`, les sous-systèmes se créent seuls.

### 4.2 `AEPOGameMode` (AGameModeBase) et `AEPOPlayerController`
- Le GameMode crée la scène de base (lumière directionnelle, `SkyLight`,
  `SkyAtmosphere`, brouillard, volume de post-traitement non borné) et une caméra
  « vide » pour les écrans 2D, puis appelle `Nav->GotoNow("title")` au `BeginPlay`.
  Pas de pion (`DefaultPawnClass = nullptr`).
- Le PlayerController affiche la souris (`bShowMouseCursor`), active les clics et
  le survol, et se met en mode d'entrée « jeu et interface ».
- Fonctions utiles exposées par le GameMode :
  `ADirectionalLight* GetSun()`, `void SetEnvironment(const FEPOObj& Preset)`
  (couleurs du ciel/brouillard pour la bataille et l'atelier), `void ResetEnvironment()`.

### 4.3 `UEPOContentSubsystem` (UGameInstanceSubsystem) — port de `content.gd`
```cpp
FString DataRoot() const;                       // voir §2
FString DataPath(const FString& Rel) const;     // DataRoot()/data/<Rel>
FString AudioPath(const FString& Name) const;   // .../assets/audio/<Name>.wav
FString FontPath(const FString& File) const;    // .../assets/fonts/<File>

FEPOArr Eras;  FEPOObj Units;  FEPOArr Battles;  FEPOArr Cards;
TMap<FString, FEPOObj> Weapons;  TArray<FString> WeaponOrder;
FEPOObj StateDecks;  FEPOObj Daily;  FEPOObj Economy;  FEPOArr Videos;
FEPOArr Briefs;  FEPOObj DesignCatalog;  FEPOArr DesignStats;

FEPOObj Era(const FString& Id) const;           int32 EraIndex(const FString& Id) const;
FEPOObj History(const FString& EraId);          // mis en cache
TArray<FEPOObj> UnitsForEra(const FString& EraId) const;     // triées par coût
TArray<FEPOObj> BattlesForEra(const FString& EraId) const;   FEPOObj Battle(const FString& Id) const;
TArray<FEPOObj> CardsForEra(const FString& EraId) const;
TArray<FEPOObj> WeaponsForEra(const FString& EraId) const;
TArray<FEPOObj> VideosForEra(const FString& EraId) const;
FEPOObj Unit(const FString& Id) const;
```
Accès : `UEPOContentSubsystem::Get(const UObject* WorldContext)` (statique, comme
pour tous les sous-systèmes ci-dessous).

### 4.4 `UEPOGameSubsystem` (UGameInstanceSubsystem) — port de `game.gd`
Mêmes fonctions et mêmes règles que `game.gd` (21 grades, solde, étoiles,
records, cartes, statistiques, réglages), même format de profil (un `FEPOObj`).
Sauvegarde : `FPaths::ProjectSavedDir()/EPO/profils.json` et `parametres.json`.
```cpp
FEPOObj Current;                                // profil actif (nullptr si aucun)
FEPOObj Settings;
bool HasProfile() const;  TArray<FEPOObj> Profiles() const;
FEPOObj NewProfile(const FString& Pseudo, const FString& Nation);
void SelectProfile(const FString& Id);  void DeleteProfile(const FString& Id);
int32 Xp() const;  int32 Solde() const;
int32 RankIndex(int32 XpValue = -1) const;  FString RankName(int32 XpValue = -1) const;
TArray<double> RankProgress() const;            // comme rank_progress()
void AddXp(int32 Amount, const FString& Reason = FString());
void AddSolde(int32 Amount);  bool Spend(int32 Amount);
void Reward(int32 XpAmount, int32 SoldeAmount, const FString& Reason);
FEPOObj Progress(const FString& EraId);
bool SetStep(const FString& EraId, const FString& Step, int32 Score);
int32 StepScore(const FString& EraId, const FString& Step) const;
double EraCompletion(const FString& EraId) const;
bool SetBest(const FString& Key, double Value, bool bLowerIsBetter = false);
bool HasBest(const FString& Key) const;  double Best(const FString& Key, double Fallback = 0.0) const;
void StatAdd(const FString& Key, int32 Amount = 1);
int32 CardCount(const FString& CardId) const;  bool AddCard(const FString& CardId);
void Save();  void SaveSettings();  void ApplySettings();
static const TArray<TPair<FString, int32>>& Ranks();   // (nom, XP)
static constexpr int32 CratePrice = 100;

DECLARE_MULTICAST_DELEGATE(FEPOOnProfileChanged);       FEPOOnProfileChanged OnProfileChanged;
DECLARE_MULTICAST_DELEGATE_TwoParams(FEPOOnXp, int32, const FString&); FEPOOnXp OnXpGained;
DECLARE_MULTICAST_DELEGATE_OneParam(FEPOOnSolde, int32); FEPOOnSolde OnSoldeChanged;
DECLARE_MULTICAST_DELEGATE_OneParam(FEPOOnRankUp, const FString&); FEPOOnRankUp OnRankUp;
```
Les délégués sont déclarés hors de la classe, avec ces noms de types.

### 4.5 `UEPOSfxSubsystem` (UGameInstanceSubsystem) — port de `sfx.gd`
Charge les `.wav` (PCM 16 bits mono, 22 050 Hz) à l'exécution et les joue avec
`USoundWaveProcedural` (une nouvelle onde par lecture).
```cpp
void Play(const FString& Name, float VolumeDb = 0.f);
void Play3D(const FString& Name, const FVector& UeLocation, float VolumeDb = 0.f, float MaxPerSec = 0.f);
void Music(const FString& Name);    // "march", "ambient", "battle" -> music_<name>.wav en boucle ; "" = arrêt
void RefreshVolumes();              // d'après Settings (musique, effets)
```

### 4.6 `UEPONavSubsystem` (UGameInstanceSubsystem) — port de `nav.gd` + couches de `ui.gd`
- Crée une fois un widget racine `UEPORootWidget` (§5.5) ajouté au viewport.
- Les écrans sont des sous-classes de `UEPOScreen` enregistrées par nom :
```cpp
// Dans le .cpp de chaque écran (hors de toute fonction) :
EPO_REGISTER_SCREEN(title, UEPOTitleScreen);   // nom Nav = "title"
```
  La macro crée un objet statique qui stocke `TEXT("title")` et un lambda
  renvoyant `UEPOTitleScreen::StaticClass()` (évalué plus tard, jamais à
  l'initialisation statique). Défini dans `Core/EPONavSubsystem.h`.
- API :
```cpp
void Goto(const FString& Screen, FEPOObj Params = nullptr);     // fondu au noir puis changement
void GotoNow(const FString& Screen, FEPOObj Params = nullptr);
UEPOScreen* Current() const;  FEPOObj Params() const;  FString CurrentName() const;
UEPORootWidget* Root() const;
// Raccourcis vers la couche racine :
void Toast(const FString& Text, const FLinearColor& Color);
UWidget* Modal(UWidget* Content, float Width = 640.f);          // renvoie l'« ombre » à fermer
void CloseModal(UWidget* Shade);
UWidget* Message(const FString& Heading, const FString& BBCode, const FString& Ok = TEXT("Compris"), TFunction<void()> OnOk = nullptr);
```
- Noms d'écrans (identiques à Godot) : `title, profiles, hub, era, history, quiz,
  battle, battle_menu, workshop, workshop_menu, state, economy, daily, crates,
  barracks, videos, settings, codex, design`.
- Au changement d'écran : `OnLeave()` de l'ancien écran (détruit ses acteurs 3D),
  retrait du widget, puis création du nouveau (`CreateWidget`, `Params`, ajout dans
  la couche écran de la racine).

## 5. Interface (`UI/`)

### 5.1 `EPOStyle` (namespace) — port des constantes et polices de `ui.gd`
```cpp
namespace EPOStyle
{
	extern EPO_API const FLinearColor BG, PANEL, PANEL_LIGHT, BORDER, GOLD, GOLD_DARK,
		TEXT, MUTED, RED, GREEN, BLUE_TEAM, RED_TEAM, PAPER, INK;
	EPO_API FLinearColor Hex(const TCHAR* Hex);          // sRGB -> linéaire
	EPO_API FLinearColor RarityColor(const FString& Rarity);
	EPO_API FString RarityName(const FString& Rarity);
	enum class EFont : uint8 { Ui, UiBold, Title, Read, ReadBold, ReadItalic };
	EPO_API FSlateFontInfo Font(EFont Font, int32 Size); // TTF lus à l'exécution, DejaVu Sans en secours pour les symboles
	EPO_API FString Nbsp(const FString& Text);            // espaces insécables à la française (comme UI.nbsp)
	EPO_API FString Dec(double X, int32 Digits = 1);      // 1,5 au lieu de 1.5
	EPO_API FString Stars(int32 N, int32 Total = 3);      // "★★☆"
	EPO_API FSlateBrush Box(const FLinearColor& Bg, const FLinearColor& Border, float BorderW = 2.f, float Radius = 4.f);
}
```
Couleurs exactes : celles de `ui.gd` (`BG = #14170f`, `PANEL = #212819`, etc.), à
convertir avec `FLinearColor::FromSRGBColor(FColor::FromHex(...))`.

### 5.2 Widgets à rappel natif
Les délégués UMG sont dynamiques (pas de lambda). On fournit donc des sous-classes
avec un `TFunction` :
```cpp
UCLASS() class EPO_API UEPOButton : public UButton    { public: TFunction<void()> OnClick; bool bHoverSound = true; /* + texte enfant */ };
UCLASS() class EPO_API UEPOSlider : public USlider    { public: TFunction<void(float)> OnChange; };
UCLASS() class EPO_API UEPOCheck : public UCheckBox   { public: TFunction<void(bool)> OnToggle; };
UCLASS() class EPO_API UEPOCombo : public UComboBoxString { public: TFunction<void(int32)> OnPick; };
UCLASS() class EPO_API UEPOText : public UEditableTextBox { public: TFunction<void(const FString&)> OnEdit; };
```
Chacune relie son délégué dynamique à une `UFUNCTION` interne qui appelle le
`TFunction`.

### 5.3 Fabrique de widgets (`UI/EPOWidgets.h`, namespace `EPOW`) — port des aides de `ui.gd`
Toutes les fonctions prennent l'arbre de widgets de l'écran (`UWidgetTree* T`).
```cpp
UTextBlock* Label(UWidgetTree* T, const FString& Text, int32 Size = 20, FLinearColor Color = EPOStyle::TEXT, EPOStyle::EFont Font = EPOStyle::EFont::Ui);
UTextBlock* WrapLabel(UWidgetTree* T, const FString& Text, int32 Size = 19, FLinearColor Color = EPOStyle::TEXT);
UTextBlock* Title(UWidgetTree* T, const FString& Text, int32 Size = 48, FLinearColor Color = EPOStyle::GOLD);
UEPORichText* Rich(UWidgetTree* T, const FString& BBCode, bool bReading = false, int32 Size = 20, FLinearColor Color = EPOStyle::TEXT);
UEPOButton* Button(UWidgetTree* T, const FString& Text, TFunction<void()> OnClick, int32 Size = 21, float MinW = 0.f);
UEPOButton* PrimaryButton(UWidgetTree* T, const FString& Text, TFunction<void()> OnClick, int32 Size = 24, float MinW = 0.f);
UEPOButton* ToggleButton(...);                       // bouton à état (onglets) : SetPressedLook(bool)
UBorder* Panel(UWidgetTree* T, float Pad = 16.f, FLinearColor Bg = EPOStyle::PANEL, FLinearColor Border = EPOStyle::BORDER);
UBorder* PaperPanel(UWidgetTree* T, float Pad = 24.f);
UVerticalBox* VBox(UWidgetTree* T);  UHorizontalBox* HBox(UWidgetTree* T);
UScrollBox* Scroll(UWidgetTree* T);  UWrapBox* Wrap(UWidgetTree* T);  UUniformGridPanel* Grid(UWidgetTree* T);
USpacer* Spacer(UWidgetTree* T, float H);  UWidget* Expander(UWidgetTree* T);
UProgressBar* Progress(UWidgetTree* T, float Value01, FLinearColor Fill, float Height = 14.f);
UImage* ColorRect(UWidgetTree* T, FLinearColor Color);
UWidget* TopBar(UEPOScreen* Screen, const FString& Title, TFunction<void()> OnBack);  // barre du haut (retour, grade, XP, solde)
UWidget* MapBackground(UEPOScreen* Screen, FLinearColor Tint = EPOStyle::BG);          // fond « carte topographique »
// Ajout dans un conteneur, quel que soit son type de slot :
UPanelSlot* Add(UPanelWidget* Parent, UWidget* Child, float Fill = 0.f, FMargin Pad = FMargin(0),
	EHorizontalAlignment H = HAlign_Fill, EVerticalAlignment V = VAlign_Fill);
void Clear(UPanelWidget* Parent);
void Pin(UWidget* W, FVector2D Anchor, FVector2D Offset);   // placement dans un UCanvasPanel (comme UI.pin)
```
`Add` règle `Size` (Fill = proportion, 0 = Auto), `Padding` et alignements pour
les slots de VerticalBox, HorizontalBox, Overlay, ScrollBox, Border, SizeBox,
WrapBox et CanvasPanel.

### 5.4 `UEPORichText` (URichTextBlock) — remplace les RichTextLabel BBCode
`void SetBBCode(const FString& BBCode, bool bReading, int32 Size, FLinearColor Color)` :
convertit les balises utilisées dans les données et le code Godot (`[b]`, `[i]`,
`[color=#hex]`, `[font_size=N]`, `[center]`) en balises URichTextBlock. Comme
URichTextBlock n'imbrique pas les styles, chaque morceau de texte reçoit un style
calculé (gras + italique + couleur + taille) ajouté à la volée dans une table de
styles `UDataTable` (`FRichTextStyleRow`) créée en code. Les `<` littéraux sont
échappés. Applique `EPOStyle::Nbsp`.

### 5.5 `UEPOScreen` (UUserWidget) et `UEPORootWidget`
```cpp
UCLASS(Abstract) class EPO_API UEPOScreen : public UUserWidget
{
public:
	FEPOObj Params;                         // paramètres de navigation (Nav.params)
	UPROPERTY() TObjectPtr<UOverlay> Root;  // racine plein écran
	virtual void Build() {}                 // construit l'écran (appelé une fois)
	virtual void OnLeave();                 // détruit les acteurs suivis
	virtual void TestAction(const FString& Action) {}
	AActor* Track(AActor* A);               // acteur détruit à la sortie de l'écran
	UWidgetTree* T() const;
	UWorld* W() const;                      // GetWorld()
protected:
	virtual TSharedRef<SWidget> RebuildWidget() override; // crée Root (UOverlay) si besoin puis appelle Build()
	virtual void NativeDestruct() override;
	UPROPERTY() TArray<TObjectPtr<AActor>> Tracked;
};
```
Les écrans qui ont besoin du temps réel surchargent `NativeTick`. Les écrans 3D
(titre, bataille, atelier) laissent le fond transparent et placent la caméra via
le PlayerController (`SetViewTargetWithBlend`).

`UEPORootWidget` (UUserWidget construit en code) : `ScreenLayer` (UOverlay),
`ModalLayer` (UOverlay), `ToastBox` (VerticalBox en haut à droite), `Fade`
(UImage noire). Il gère dans `NativeTick` le fondu et la durée de vie des toasts.
Fonctions : `ShowScreen(UEPOScreen*)`, `Toast`, `Modal`, `CloseModal`,
`FadeOut(TFunction<void()> Then)`, `FadeIn()`. Il écoute `OnXpGained` et
`OnRankUp` du sous-système de jeu (toast « +30 XP », bandeau de nouveau grade),
comme `ui.gd`.

## 6. Modèles 3D (`Models/`)

### 6.1 `FEPOMat` et `UEPOMaterialSubsystem`
```cpp
struct EPO_API FEPOMat
{
	FLinearColor Color = FLinearColor::Gray; float Rough = 0.85f; float Metal = 0.f; float Emit = 0.f; float Alpha = 1.f;
	static FEPOMat Of(const FLinearColor& C, float Rough = 0.85f, float Metal = 0.f, float Emit = 0.f); // comme Models.mat
	static FEPOMat MetalOf(const FLinearColor& C);                                                         // comme Models.metal_mat
	FString Key() const;
};
UCLASS() class EPO_API UEPOMaterialSubsystem : public UGameInstanceSubsystem
{
	UMaterialInstanceDynamic* Get(const FEPOMat& M);   // mis en cache par clé
	// Parent : /Game/EPO/Materials/M_EPO_Master (opaque) ou M_EPO_Translucent (Alpha < 1),
	// paramètres "Color" (vecteur), "Roughness", "Metallic", "Emissive", "Opacity".
	// À défaut : /Engine/BasicShapes/BasicShapeMaterial (paramètre "Color").
};
```

### 6.2 `FEPOMeshBuilder` — port de `Models.box/cyl/sphere/capsule/torus/prism`
Les arguments sont **en espace Godot** (mètres, rotations en radians, ordre YXZ),
exactement comme les appels GDScript. Le constructeur convertit en interne.
```cpp
class EPO_API FEPOMeshBuilder
{
public:
	void Box(const FVector& Size, const FEPOMat& M, const FVector& Pos = FVector::ZeroVector, const FVector& Rot = FVector::ZeroVector);
	void Cyl(float RTop, float RBot, float H, const FEPOMat& M, const FVector& Pos = FVector::ZeroVector, const FVector& Rot = FVector::ZeroVector, int32 Segs = 12); // axe Y Godot
	void Sphere(float R, const FEPOMat& M, const FVector& Pos = FVector::ZeroVector, const FVector& Scale = FVector::OneVector, bool bHemi = false);
	void Capsule(float R, float H, const FEPOMat& M, const FVector& Pos = FVector::ZeroVector, const FVector& Rot = FVector::ZeroVector, const FVector& Scale = FVector::OneVector);
	void Torus(float Inner, float Outer, const FEPOMat& M, const FVector& Pos = FVector::ZeroVector, const FVector& Rot = FVector::ZeroVector); // axe Y Godot
	void Prism(const FVector& Size, const FEPOMat& M, const FVector& Pos = FVector::ZeroVector, const FVector& Rot = FVector::ZeroVector);   // PrismMesh Godot
	bool IsEmpty() const;  void Reset();
	// Une section par matériau. bCollision : collision de requête (clic sur les pièces de l'atelier).
	void Commit(UProceduralMeshComponent* Comp, UEPOMaterialSubsystem* Mats, bool bCollision = false) const;
};
```
Mêmes dimensions que les maillages Godot correspondants (`BoxMesh`,
`CylinderMesh`, `SphereMesh`, `CapsuleMesh` dont `H` est la hauteur totale,
`TorusMesh` inner/outer, `PrismMesh` triangle à sommet centré).

### 6.3 Pièces et pivots (`Models/EPOModels.h`, namespace `EPOModels`) — port de `models.gd`
```cpp
USceneComponent* NewPivot(USceneComponent* Parent, FName Name, const FVector& GPos = FVector::ZeroVector, const FVector& GRot = FVector::ZeroVector);
UProceduralMeshComponent* NewPart(USceneComponent* Parent, FName Name, const FEPOMeshBuilder& B, bool bCollision = false);
void SetGodotTransform(USceneComponent* C, const FVector& GPos, const FVector& GRot, const FVector& GScale = FVector::OneVector);
FLinearColor Col(const FEPOVal& V, const FLinearColor& Fallback = FLinearColor::Gray);   // comme Models.col
void Headgear(USceneComponent* Parent, const FString& Kind, const FLinearColor& C, const FLinearColor& Accent);
void HandWeapon(USceneComponent* Parent, const FString& Kind);
void Shield(USceneComponent* Parent, const FString& Kind, const FLinearColor& C, const FLinearColor& Accent);
extern const TArray<FLinearColor> Skins;
```
Composants créés avec `NewObject` (outer = acteur propriétaire), attachés, puis
`RegisterComponent()`.

### 6.4 Modèles animés (composants) — ports de `soldier_model.gd`, `horse_model.gd`, `vehicle_model.gd`
```cpp
UCLASS() class EPO_API UEPOSoldierModel : public USceneComponent
{ void Build(const FEPOObj& Cfg); void PlayAttack(float Duration = 0.35f); void Animate(float Dt, float Speed, bool bAiming); /* pivots publics : Rig, Body, Head, ArmL, ArmR, LegL, LegR, Weapon, ShieldNode, Mount */ };
UCLASS() class EPO_API UEPOHorseModel : public USceneComponent  { void Build(const FLinearColor& C); void Animate(float Dt, float Speed); float Bob = 0.f; };
UCLASS() class EPO_API UEPOVehicleModel : public USceneComponent
{ void Build(const FString& Kind, const FLinearColor& C, const FLinearColor& Accent, const FEPOObj& CrewCfg); void Animate(float Dt, float Speed); void FireAnim();
  /* Turret, Barrel, Muzzle, Arm, Rotor, Wheels, Crew, HoverHeight comme en Godot */ };
```
Fabriques : `UEPOSoldierModel* EPOModels::Soldier(USceneComponent* Parent, const FEPOObj& Cfg)` etc.
Animation procédurale identique à Godot, appelée par le propriétaire chaque frame.

### 6.5 Aperçu 3D dans l'interface — port de `model_view.gd`
`AEPOPreviewStage` (AActor) : pivot tournant + lumière + `USceneCaptureComponent2D`
vers un `UTextureRenderTarget2D`, avec `ShowOnlyActors = {this}`, placé loin de la
scène (chaque scène d'aperçu à son propre décalage). `static Spawn(UWorld*, FIntPoint Res)`,
`GetTarget()`, `GetPivot()`, `Frame(float GHeight)`, `SetSpin(float DegPerSec)`.
`UImage* EPOModels::ModelView(UEPOScreen* S, FVector2D Size, AEPOPreviewStage*& OutStage)`
(déclarée dans `Models/EPOPreviewStage.h`) crée l'image (brush = render target) et
suit l'acteur via `S->Track`.

## 7. Écrans, bataille, atelier

Chaque écran Godot `screens/X.gd` devient `Screens/EPOXScreen.h/.cpp`
(`UEPOXScreen : UEPOScreen`, enregistré sous le même nom). La bataille et
l'atelier suivent la même découpe que Godot (`Battle/EPOBattle…`,
`Workshop/EPOWorkshop…`). Leurs contrats détaillés sont ajoutés ici avant leur
écriture.

## 8. Fichiers de configuration (rappel)

- `EPO.uproject` : `EngineAssociation` `5.8`, module `EPO` (Runtime, Default),
  plugins `ProceduralMeshComponent`, `PythonScriptPlugin`,
  `EditorScriptingUtilities`, et le plugin MCP officiel d'Epic (expérimental) pour
  piloter l'éditeur avec Claude Code.
- `DefaultEngine.ini` : `GameDefaultMap` et `EditorStartupMap` =
  `/Engine/Maps/Entry`, `GameInstanceClass=/Script/EPO.EPOGameInstance`,
  `GlobalDefaultGameMode=/Script/EPO.EPOGameMode`, fenêtre 1600×900.
- `DefaultGame.ini` : nom du projet, `+DirectoriesToAlwaysStageAsNonUFS=(Path="EPOData")`,
  `+DirectoriesToAlwaysCook=(Path="/Engine/BasicShapes")`,
  `+MapsToCook=(FilePath="/Engine/Maps/Entry")`.
