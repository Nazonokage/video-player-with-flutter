# Clean Player - Project Flow Chart

```mermaid
flowchart TD
    A[App Start] --> B[main.dart]
    B --> C[MediaKit.ensureInitialized]
    C --> D[AppRoot Widget]
    
    D --> E[Load StateStore]
    E --> F[Initialize PlaylistService]
    F --> G[FutureBuilder]
    
    G --> H{State Loaded?}
    H -->|No| I[Loading Screen]
    H -->|Yes| J[LibraryScreen]
    
    J --> K[Show Recent Files]
    K --> L{User Action}
    
    L -->|Open File| M[FilePicker]
    L -->|Open Folder| N[FolderPicker]
    L -->|Select Recent| O[Open Recent File]
    L -->|Clear Recents| P[Clear All Recents]
    
    M --> Q[Add to Playlist]
    N --> R[Scan Folder for Videos]
    R --> Q
    O --> S[Add to Playlist if not exists]
    
    Q --> T[Navigate to PlayerScreen]
    S --> T
    
    T --> U[PlayerController Setup]
    U --> V[Open Media File]
    V --> W[Resume from Last Position]
    W --> X[Setup Player Listeners]
    
    X --> Y[Player UI]
    Y --> Z[Video Display]
    Y --> AA[Controls Bar]
    Y --> BB[Seek Bar]
    Y --> CC[Top Bar]
    
    CC --> DD[Playlist Modal]
    CC --> EE[Subtitle Menu]
    CC --> FF[Help Dialog]
    
    AA --> GG{User Controls}
    GG -->|Play/Pause| HH[Toggle Playback]
    GG -->|Next/Prev| II[Navigate Playlist]
    GG -->|Seek| JJ[Update Position]
    GG -->|Volume| KK[Adjust Volume]
    GG -->|Speed| LL[Change Playback Speed]
    GG -->|Fullscreen| MM[Enter Fullscreen]
    
    HH --> NN[Update UI State]
    II --> OO[Load New File]
    JJ --> PP[Update Seek Position]
    KK --> QQ[Update Volume Display]
    LL --> RR[Update Speed Display]
    MM --> SS[Fullscreen Player]
    
    OO --> V
    NN --> Y
    PP --> Y
    QQ --> Y
    RR --> Y
    SS --> TT[Same Controls in Fullscreen]
    
    Y --> UU[Auto-save Progress]
    UU --> VV[Save to StateStore]
    VV --> WW[Update Recent Items]
    
    WW --> XX{App Lifecycle}
    XX -->|Continue| Y
    XX -->|Exit| YY[Save Final State]
    YY --> ZZ[Dispose Resources]
    ZZ --> AAA[App End]
    
    %% State Management
    VV --> BBB[AppStateModel]
    BBB --> CCC[AppSettings]
    BBB --> DDD[RecentItem List]
    
    CCC --> EEE[Volume Setting]
    CCC --> FFF[Speed Setting]
    
    DDD --> GGG[File Path]
    DDD --> HHH[Last Position]
    DDD --> III[Duration]
    DDD --> JJJ[Last Opened Time]
    
    %% Services
    F --> KKK[PlaylistService]
    KKK --> LLL[File Management]
    KKK --> MMM[Playlist Navigation]
    
    %% Core Components
    U --> NNN[PlayerController]
    NNN --> OOO[MediaKit Player]
    NNN --> PPP[VideoController]
    NNN --> QQQ[Position Stream]
    
    %% UI Components
    Y --> RRR[TopBar]
    Y --> SSS[ControlsBar]
    Y --> TTT[SeekBar]
    Y --> UUU[OverlaySubtitle]
    
    RRR --> VVV[Playlist Button]
    RRR --> WWW[Subtitle Button]
    RRR --> XXX[Help Button]
    
    SSS --> YYY[Play/Pause Button]
    SSS --> ZZZ[Next/Prev Buttons]
    SSS --> AAAA[Speed Control]
    SSS --> BBBB[Volume Control]
    SSS --> CCCC[Fullscreen Button]
    
    TTT --> DDDD[Position Display]
    TTT --> EEEE[Duration Display]
    TTT --> FFFF[Seek Handle]
    
    %% Styling
    classDef startEnd fill:#e1f5fe
    classDef process fill:#f3e5f5
    classDef decision fill:#fff3e0
    classDef data fill:#e8f5e8
    classDef ui fill:#fce4ec
    
    class A,AAA startEnd
    class B,C,D,E,F,G,U,V,W,X,OO,NN,PP,QQ,RR,UU,VV,WW,YY,ZZ process
    class H,L,GG,XX decision
    class BBB,CCC,DDD,EEE,FFF,GGG,HHH,III,JJJ data
    class J,Y,Z,AA,BB,CC,DD,EE,FF,MM,SS,RRR,SSS,TTT,UUU,UUU,WWW,XXX,YYY,ZZZ,AAAA,BBBB,CCCC,DDDD,EEEE,FFFF ui
```

## Key Flow Points:

1. **App Initialization**: MediaKit setup → State loading → Library screen
2. **File Selection**: File/Folder picker → Playlist management → Player navigation
3. **Player Experience**: Media loading → Resume position → Real-time controls
4. **State Persistence**: Auto-save progress → Update recents → Maintain settings
5. **UI Components**: Modular design with TopBar, ControlsBar, SeekBar, and overlays

## Architecture Highlights:

- **State Management**: Centralized with AppStateModel and StateStore
- **Service Layer**: PlaylistService for file management
- **Controller Pattern**: PlayerController wraps MediaKit functionality
- **Reactive UI**: Stream-based updates for position and playback state
- **Platform Support**: Cross-platform with platform-specific optimizations
