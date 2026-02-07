# LegalSteward - Visual Diagrams

This document contains Mermaid diagrams for visualizing the LegalSteward architecture and workflows.

---

## 1. System Architecture Diagram

```mermaid
graph TB
    subgraph "Presentation Layer"
        V1[Splash View]
        V2[Login View]
        V3[Dashboard View]
        V4[Clients View]
        V5[Cases View]
        V6[Tasks View]
        V7[Billing Views]
    end
    
    subgraph "Controller Layer"
        C1[SplashController]
        C2[LoginController]
        C3[DashboardController]
        C4[ClientsController]
        C5[CasesController]
        C6[TaskController]
    end
    
    subgraph "Service Layer"
        S1[PdfInvoiceService]
        S2[NotificationService]
        S3[AppUpdateService]
        S4[ContactImportService]
    end
    
    subgraph "Data Layer"
        D1[(Clients Box)]
        D2[(Cases Box)]
        D3[(Tasks Box)]
        D4[(TimeEntries Box)]
        D5[(Expenses Box)]
        D6[(Invoices Box)]
        D7[(User Box)]
    end
    
    subgraph "External Services"
        E1[Firebase Auth]
        E2[Google Drive API]
        E3[Google AdMob]
    end
    
    V1 --> C1
    V2 --> C2
    V3 --> C3
    V4 --> C4
    V5 --> C5
    V6 --> C6
    V7 --> C4
    V7 --> C5
    
    C2 --> E1
    C2 --> E2
    C3 --> S3
    C4 --> D1
    C5 --> D2
    C6 --> D3
    
    S1 --> D2
    S1 --> D4
    S1 --> D5
    S1 --> D6
    
    C2 --> D7
    
    V3 -.ads.-> E3
```

---

## 2. Entity Relationship Diagram

```mermaid
erDiagram
    USER ||--o{ CLIENT : manages
    USER ||--o{ CASE : manages
    USER ||--o{ TASK : creates
    
    CLIENT ||--o{ CASE : "has"
    
    CASE ||--o{ TASK : "linked to"
    CASE ||--o{ TIME_ENTRY : "tracks"
    CASE ||--o{ EXPENSE : "incurs"
    CASE ||--o{ INVOICE : "generates"
    
    INVOICE ||--o{ TIME_ENTRY : "includes"
    INVOICE ||--o{ EXPENSE : "includes"
    
    USER {
        string id PK
        string name
        string email
        string phone
        string city
        string state
        string photoUrl
        datetime createdAt
    }
    
    CLIENT {
        string id PK
        string name
        string contactNumber
        string email
        string city
        string state
    }
    
    CASE {
        string id PK
        string title
        string clientId FK
        string clientName
        string court
        string caseNo
        string status
        datetime nextHearing
        string notes
    }
    
    TASK {
        string id PK
        string title
        string description
        datetime dueDate
        bool hasReminder
        string linkedCaseId FK
        bool isCompleted
    }
    
    TIME_ENTRY {
        string id PK
        string caseId FK
        datetime date
        string description
        double hours
        double rate
    }
    
    EXPENSE {
        string id PK
        string caseId FK
        datetime date
        string title
        double amount
        string notes
    }
    
    INVOICE {
        string id PK
        string caseId FK
        list timeEntryIds
        list expenseIds
        double totalAmount
        datetime invoiceDate
        bool isPaid
    }
```

---

## 3. Application Flow Diagram

```mermaid
flowchart TD
    Start([App Launch]) --> Init[Initialize Firebase & Hive]
    Init --> RegAdapters[Register Hive Adapters]
    RegAdapters --> OpenBoxes[Open All Hive Boxes]
    OpenBoxes --> InitAds[Initialize AdMob]
    InitAds --> Splash[Splash Screen]
    
    Splash --> CheckAuth{User Authenticated?}
    
    CheckAuth -->|No| Login[Login Screen]
    Login --> GoogleSignIn[Google Sign-In]
    GoogleSignIn --> FirebaseAuth[Firebase Authentication]
    FirebaseAuth --> SaveUser[Save User to Hive]
    SaveUser --> TryRestore{Backup on Drive?}
    TryRestore -->|Yes| Restore[Restore from Drive]
    TryRestore -->|No| Dashboard
    Restore --> Dashboard
    
    CheckAuth -->|Yes| Dashboard[Dashboard]
    
    Dashboard --> Features{Select Feature}
    
    Features -->|Clients| ClientList[Client List]
    ClientList --> ClientOps{Operation}
    ClientOps -->|Add| AddClient[Add Client Form]
    ClientOps -->|Edit| EditClient[Edit Client]
    ClientOps -->|Delete| DeleteClient[Delete Client]
    AddClient --> SaveClient[Save to Hive]
    EditClient --> SaveClient
    DeleteClient --> RemoveClient[Remove from Hive]
    
    Features -->|Cases| CaseList[Case List]
    CaseList --> CaseOps{Operation}
    CaseOps -->|Add| AddCase[Add Case Form]
    CaseOps -->|Edit| EditCase[Edit Case]
    CaseOps -->|Delete| DeleteCase[Delete Case]
    AddCase --> SaveCase[Save to Hive]
    EditCase --> SaveCase
    DeleteCase --> RemoveCase[Remove from Hive]
    
    Features -->|Tasks| TaskList[Task List]
    TaskList --> TaskOps{Operation}
    TaskOps -->|Add| AddTask[Add Task Form]
    TaskOps -->|Complete| ToggleTask[Toggle Completion]
    TaskOps -->|Delete| DeleteTask[Delete Task]
    AddTask --> SaveTask[Save to Hive]
    ToggleTask --> UpdateTask[Update Task]
    
    Features -->|Billing| BillingDash[Billing Overview]
    BillingDash --> BillingOps{Operation}
    BillingOps -->|Time Entry| AddTimeEntry[Add Time Entry]
    BillingOps -->|Expense| AddExpense[Add Expense]
    BillingOps -->|Invoice| CreateInvoice[Create Invoice]
    
    CreateInvoice --> SelectCase[Select Case]
    SelectCase --> SelectItems[Select Time Entries & Expenses]
    SelectItems --> CalcTotal[Calculate Total]
    CalcTotal --> SaveInvoice[Save Invoice]
    SaveInvoice --> GenPDF[Generate PDF]
    GenPDF --> SharePDF[Share/Save PDF]
    
    Dashboard --> Backup{Backup Action}
    Backup -->|Backup| BackupToDrive[Backup to Google Drive]
    BackupToDrive --> CreateZip[Create ZIP of Hive Files]
    CreateZip --> Upload[Upload to Drive]
```

---

## 4. Data Flow - Client Management

```mermaid
sequenceDiagram
    participant U as User
    participant V as ClientsView
    participant C as ClientsController
    participant H as Hive Clients Box
    
    U->>V: Navigate to Clients
    V->>C: Request client list
    C->>H: Get all clients
    H-->>C: Return clients
    C-->>V: Update filteredClients.obs
    V-->>U: Display client list
    
    U->>V: Enter search query
    V->>C: updateSearchQuery(query)
    C->>C: Update searchQuery.obs
    C->>C: Compute filteredClients
    C-->>V: Trigger Obx rebuild
    V-->>U: Display filtered results
    
    U->>V: Tap "Add Client"
    V->>V: Navigate to AddClientView
    U->>V: Fill form and save
    V->>C: addClient(clientData)
    C->>C: Create ClientModel
    C->>H: Add client to box
    H-->>C: Confirm saved
    C->>C: Hive watch listener triggered
    C->>C: Reload clients
    C-->>V: Update filteredClients.obs
    V-->>U: Show updated list
```

---

## 5. Data Flow - Invoice Generation

```mermaid
sequenceDiagram
    participant U as User
    participant V as AddInvoiceView
    participant C as Controller
    participant HB as Hive Boxes
    participant PS as PdfInvoiceService
    
    U->>V: Navigate to Create Invoice
    V->>C: Get cases list
    C->>HB: Query cases box
    HB-->>C: Return cases
    C-->>V: Display cases
    
    U->>V: Select case
    V->>C: Get time entries for case
    C->>HB: Query time_entries box
    HB-->>C: Return entries
    C-->>V: Display time entries
    
    U->>V: Select time entries
    V->>C: Get expenses for case
    C->>HB: Query expenses box
    HB-->>C: Return expenses
    C-->>V: Display expenses
    
    U->>V: Select expenses
    V->>C: Calculate total
    C->>C: Sum (hours * rate) + expenses
    C-->>V: Display total
    
    U->>V: Tap "Generate Invoice"
    V->>C: createInvoice(data)
    C->>C: Create InvoiceModel
    C->>HB: Save to invoices box
    HB-->>C: Confirm saved
    
    C->>PS: generate(invoice)
    PS->>HB: Fetch case details
    PS->>HB: Fetch time entries
    PS->>HB: Fetch expenses
    HB-->>PS: Return data
    PS->>PS: Build PDF document
    PS-->>C: Return PDF bytes
    
    C-->>V: Provide PDF file
    V->>U: Show share/save options
    U->>V: Share/Save PDF
```

---

## 6. Authentication Flow

```mermaid
stateDiagram-v2
    [*] --> Splash
    Splash --> CheckingAuth: Check Auth Status
    
    CheckingAuth --> Dashboard: Authenticated
    CheckingAuth --> Login: Not Authenticated
    
    Login --> GoogleSignIn: User Taps Sign In
    GoogleSignIn --> Authenticating: Google Auth Flow
    
    Authenticating --> AuthSuccess: Success
    Authenticating --> AuthError: Failed
    
    AuthError --> Login: Show Error
    
    AuthSuccess --> SaveUserData: Firebase Credential Created
    SaveUserData --> CheckBackup: User Saved to Hive
    
    CheckBackup --> RestoreData: Backup Found
    CheckBackup --> Dashboard: No Backup
    
    RestoreData --> DownloadBackup: Download from Drive
    DownloadBackup --> ExtractBackup: Extract ZIP
    ExtractBackup --> OverwriteLocal: Overwrite Hive Files
    OverwriteLocal --> Dashboard: Data Restored
    
    Dashboard --> [*]: App Running
```

---

## 7. Backup & Restore Flow

```mermaid
flowchart LR
    subgraph Backup Process
        B1[User Taps Backup] --> B2[Show Loading Dialog]
        B2 --> B3[Silent Google Sign-In]
        B3 --> B4{Authenticated?}
        B4 -->|No| B5[Show Error]
        B4 -->|Yes| B6[Get Auth Headers]
        B6 --> B7[Create Temp Directory]
        B7 --> B8[Copy All Hive Files]
        B8 --> B9[Create ZIP Archive]
        B9 --> B10[Upload to Drive]
        B10 --> B11[Delete Old Backup]
        B11 --> B12[Save New Backup]
        B12 --> B13[Close Dialog]
        B13 --> B14[Show Success]
    end
    
    subgraph Restore Process
        R1[Login/Sign-In] --> R2[Check Drive for Backup]
        R2 --> R3{Backup Found?}
        R3 -->|No| R4[Skip Restore]
        R3 -->|Yes| R5[Download ZIP from Drive]
        R5 --> R6[Extract to Temp Dir]
        R6 --> R7[Overwrite Local Hive Files]
        R7 --> R8[Reopen Hive Boxes]
        R8 --> R9[Navigate to Dashboard]
    end
```

---

## 8. Task Management State Machine

```mermaid
stateDiagram-v2
    [*] --> TaskList: Open Tasks
    
    TaskList --> AddingTask: Tap Add Task
    TaskList --> ViewingTask: Tap on Task
    TaskList --> DeletingTask: Swipe to Delete
    
    AddingTask --> EnterDetails: Form Displayed
    EnterDetails --> SetDueDate: Enter Title/Description
    SetDueDate --> SetReminder: Select Date
    SetReminder --> LinkCase: Enable/Disable
    LinkCase --> SaveTask: Optional Case Link
    SaveTask --> ScheduleNotif: Save to Hive
    ScheduleNotif --> TaskList: If Reminder Enabled
    SaveTask --> TaskList: Task Added
    
    ViewingTask --> EditingTask: Tap Edit
    ViewingTask --> TogglingComplete: Toggle Checkbox
    ViewingTask --> TaskList: Back
    
    EditingTask --> UpdateDetails: Modify Fields
    UpdateDetails --> SaveTask: Save Changes
    
    TogglingComplete --> UpdateStatus: Update isCompleted
    UpdateStatus --> TaskList: Refresh List
    
    DeletingTask --> ConfirmDelete: Show Confirmation
    ConfirmDelete --> RemoveTask: User Confirms
    RemoveTask --> CancelNotif: Delete from Hive
    CancelNotif --> TaskList: If Had Reminder
    RemoveTask --> TaskList: Task Deleted
    
    TaskList --> [*]: Exit
```

---

## 9. Case Lifecycle

```mermaid
stateDiagram-v2
    [*] --> UnNumbered: Case Filed
    
    UnNumbered --> Pending: Case Number Assigned
    
    Pending --> HearingScheduled: Next Hearing Set
    HearingScheduled --> Pending: Hearing Adjourned
    HearingScheduled --> Disposed: Judgment Delivered
    HearingScheduled --> Closed: Settlement/Withdrawal
    
    Pending --> Disposed: Direct Judgment
    Pending --> Closed: Settlement/Withdrawal
    
    Disposed --> [*]: Case Complete
    Closed --> [*]: Case Complete
    
    note right of Pending
        Active case with ongoing proceedings
        Multiple hearings possible
    end note
    
    note right of Disposed
        Final judgment rendered by court
    end note
    
    note right of Closed
        Case closed without judgment
        (Settlement, withdrawal, etc.)
    end note
```

---

## 10. Controller Reactive Pattern

```mermaid
flowchart TB
    subgraph View Layer
        V1[Widget Tree]
        V2[Obx Wrapper]
    end
    
    subgraph Controller
        C1[Rx Variables]
        C2[Business Methods]
        C3[Hive Box Reference]
    end
    
    subgraph Hive Storage
        H1[Box.watch Stream]
        H2[Persistent Storage]
    end
    
    V1 --> V2
    V2 -.observes.-> C1
    
    V2 -->|User Action| C2
    C2 -->|Updates| C1
    C2 -->|Read/Write| C3
    
    C3 -->|CRUD| H2
    H2 -->|Change Event| H1
    H1 -->|Triggers| C2
    C2 -->|Reloads| C1
    C1 -.triggers rebuild.-> V2
    V2 -->|Rebuilds| V1
    
    style C1 fill:#e1f5ff
    style V2 fill:#fff4e6
    style H1 fill:#e8f5e9
```

---

## 11. Module Dependency Graph

```mermaid
graph TD
    Main[main.dart] --> Routes[app_routes.dart]
    Main --> Theme[app_theme.dart]
    Main --> Models[Data Models]
    
    Routes --> Splash[Splash Module]
    Routes --> Login[Login Module]
    Routes --> Dashboard[Dashboard Module]
    Routes --> Clients[Clients Module]
    Routes --> Cases[Cases Module]
    Routes --> Tasks[Tasks Module]
    Routes --> Billing[Billing Module]
    Routes --> Calendar[Calendar Module]
    
    Login --> Auth[Firebase Auth]
    Login --> GoogleSignIn[Google Sign In]
    Login --> DriveAPI[Google Drive API]
    Login --> Models
    
    Dashboard --> AppUpdate[App Update Service]
    Dashboard --> Connectivity[Connectivity Check]
    Dashboard --> Tasks
    
    Clients --> Models
    Cases --> Models
    Tasks --> Models
    Tasks --> NotifService[Notification Service]
    
    Billing --> TimeEntries[Time Entries]
    Billing --> Expenses[Expenses]
    Billing --> Invoices[Invoices]
    Invoices --> PdfService[PDF Invoice Service]
    
    PdfService --> Models
    
    Models --> Hive[Hive Storage]
    
    style Main fill:#ffebee
    style Routes fill:#e3f2fd
    style Models fill:#f3e5f5
    style Hive fill:#e8f5e9
```

---

## 12. Search & Filter Flow

```mermaid
flowchart TD
    Start[User Opens List View] --> LoadData[Load All Items from Hive]
    LoadData --> DisplayAll[Display All Items]
    
    DisplayAll --> UserAction{User Action}
    
    UserAction -->|Search| EnterQuery[Enter Search Text]
    EnterQuery --> UpdateQuery[Update searchQuery.obs]
    UpdateQuery --> ApplyFilters
    
    UserAction -->|Filter| SelectFilter[Select Filter Option]
    SelectFilter --> UpdateFilter[Update filter.obs]
    UpdateFilter --> ApplyFilters
    
    UserAction -->|Sort| SelectSort[Select Sort Criteria]
    SelectSort --> UpdateSort[Update sortBy.obs]
    UpdateSort --> ApplyFilters
    
    ApplyFilters[Apply Filters] --> FilterText{Match Search?}
    FilterText -->|No| Exclude1[Exclude Item]
    FilterText -->|Yes| FilterCat{Match Category?}
    
    FilterCat -->|No| Exclude2[Exclude Item]
    FilterCat -->|Yes| FilterDate{Match Date Range?}
    
    FilterDate -->|No| Exclude3[Exclude Item]
    FilterDate -->|Yes| Include[Include in Results]
    
    Include --> SortResults[Sort Results]
    Exclude1 --> CheckNext{More Items?}
    Exclude2 --> CheckNext
    Exclude3 --> CheckNext
    
    SortResults --> CheckNext
    CheckNext -->|Yes| ApplyFilters
    CheckNext -->|No| UpdateUI[Update filteredItems.obs]
    
    UpdateUI --> RebuildWidget[Obx Widget Rebuilds]
    RebuildWidget --> DisplayResults[Display Filtered & Sorted Results]
    
    DisplayResults --> UserAction
```

---

## 13. Service Layer Architecture

```mermaid
graph TB
    subgraph Controllers
        C1[ClientsController]
        C2[CasesController]
        C3[TaskController]
        C4[LoginController]
    end
    
    subgraph Services
        S1[PdfInvoiceService]
        S2[NotificationService]
        S3[AppUpdateService]
        S4[ContactImportService]
        S5[Drive Backup/Restore]
    end
    
    subgraph External APIs
        E1[Firebase Auth]
        E2[Google Drive API]
        E3[Google AdMob]
        E4[In-App Update]
    end
    
    subgraph Data Access
        D1[Hive Boxes]
    end
    
    C1 --> D1
    C2 --> D1
    C3 --> D1
    C3 -.future.-> S2
    C4 --> D1
    C4 --> S5
    
    S1 --> D1
    S2 -.future.-> NotifAPI[Android Notifications]
    S3 --> E4
    S4 --> Contacts[Device Contacts]
    S5 --> E2
    
    C4 --> E1
    
    Controllers -.display ads.-> E3
    
    style S2 stroke-dasharray: 5 5
    style NotifAPI stroke-dasharray: 5 5
```

---

## 14. Billing Workflow Detail

```mermaid
flowchart TD
    Dashboard --> BillingOverview[Billing Overview]
    
    BillingOverview --> ViewTE[View Time Entries]
    BillingOverview --> ViewExp[View Expenses]
    BillingOverview --> ViewInv[View Invoices]
    BillingOverview --> AddTE[Add Time Entry]
    BillingOverview --> AddExp[Add Expense]
    BillingOverview --> CreateInv[Create Invoice]
    
    AddTE --> SelectCase1[Select Case]
    SelectCase1 --> EnterTE[Enter Hours, Rate, Description]
    EnterTE --> SaveTE[Save Time Entry]
    SaveTE --> UpdateTE[Update time_entries Box]
    
    AddExp --> SelectCase2[Select Case]
    SelectCase2 --> EnterExp[Enter Amount, Title, Notes]
    EnterExp --> AttachReceipt{Attach Receipt?}
    AttachReceipt -->|Yes| UploadReceipt[Upload Receipt]
    AttachReceipt -->|No| SaveExp
    UploadReceipt --> SaveExp[Save Expense]
    SaveExp --> UpdateExp[Update expenses Box]
    
    CreateInv --> SelectCase3[Select Case]
    SelectCase3 --> LoadTE[Load Time Entries for Case]
    LoadTE --> SelectTE[Select Time Entries]
    SelectTE --> LoadExp[Load Expenses for Case]
    LoadExp --> SelectExp[Select Expenses]
    SelectExp --> CalcTotal[Auto-Calculate Total]
    CalcTotal --> PreviewInv[Preview Invoice]
    PreviewInv --> SaveInv[Save Invoice]
    SaveInv --> GenPDF[Generate PDF]
    
    GenPDF --> LoadData[Load Case, TimeEntry, Expense Data]
    LoadData --> BuildPDF[Build PDF with Itemized List]
    BuildPDF --> ReturnPDF[Return PDF Bytes]
    ReturnPDF --> ShareOptions[Share/Save/Print Options]
```

---

## 15. Hive Box Initialization

```mermaid
sequenceDiagram
    participant M as main()
    participant F as Flutter Framework
    participant FB as Firebase
    participant H as Hive
    participant MA as MobileAds
    
    M->>F: ensureInitialized()
    F-->>M: Ready
    
    M->>FB: Firebase.initializeApp()
    FB-->>M: Firebase Ready
    
    M->>H: Hive.initFlutter()
    H-->>M: Hive Ready
    
    M->>MA: MobileAds.instance.initialize()
    MA-->>M: Ads Ready
    
    M->>H: registerAdapter(CaseModelAdapter)
    M->>H: registerAdapter(ClientModelAdapter)
    M->>H: registerAdapter(TaskModelAdapter)
    M->>H: registerAdapter(TimeEntryModelAdapter)
    M->>H: registerAdapter(ExpenseModelAdapter)
    M->>H: registerAdapter(InvoiceModelAdapter)
    M->>H: registerAdapter(UserModelAdapter)
    H-->>M: All Adapters Registered
    
    M->>H: openBox('cases')
    M->>H: openBox('clients')
    M->>H: openBox('tasks')
    M->>H: openBox('time_entries')
    M->>H: openBox('expenses')
    M->>H: openBox('invoices')
    M->>H: openBox('user')
    H-->>M: All Boxes Opened
    
    M->>M: runApp(MyApp())
```

---

## 16. Error Handling Flow

```mermaid
flowchart TD
    UserAction[User Action] --> TryCatch{Try Operation}
    
    TryCatch -->|Success| Success[Operation Successful]
    Success --> UpdateUI[Update UI]
    UpdateUI --> ShowSuccess[Show Success Message]
    
    TryCatch -->|Error| CatchError[Catch Exception]
    CatchError --> CheckType{Error Type?}
    
    CheckType -->|Network| NetworkError[Network Error]
    CheckType -->|Auth| AuthError[Authentication Error]
    CheckType -->|Permission| PermError[Permission Error]
    CheckType -->|Timeout| TimeoutError[Timeout Error]
    CheckType -->|Other| GenericError[Generic Error]
    
    NetworkError --> MapError[Map to User-Friendly Message]
    AuthError --> MapError
    PermError --> MapError
    TimeoutError --> MapError
    GenericError --> MapError
    
    MapError --> ShowSnackbar[Show Error Snackbar]
    ShowSnackbar --> LogError[Log Error]
    LogError --> RestoreState[Restore Previous State]
    RestoreState --> End[End]
    
    ShowSuccess --> End
```

---

## Conclusion

These diagrams provide visual representations of:
- System architecture and module relationships
- Data models and entity relationships
- User workflows and application flows
- State management patterns
- Service interactions
- Authentication and backup processes

Use these diagrams in conjunction with the ProjectAnalysis.md document for a complete understanding of the LegalSteward application architecture and workflows.
