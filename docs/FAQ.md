Frequently Asked Questions (FAQ)

General
What is LegalDesk?  
A practice and matter management application supporting client, case, task, time, expense, and invoice workflows with offline local persistence.

Who is the target audience?  
Solo practitioners and small legal teams needing streamlined operational oversight without heavy server infrastructure.

Is the data stored remotely?  
No. Data is stored locally using Hive. Cloud synchronization is a planned enhancement.

Authentication
Is user login functional?  
Firebase initialization is present; full multi‑user authentication and session features are slated for future development.

Can multiple users share the same data?  
Currently no synchronization layer. Multi‑device and user collaboration will require future sync and access control features.

Data & Persistence
How are entities stored?  
Each entity is serialized through a Hive adapter into its corresponding box opened at application startup.

Can I back up my data?  
Manual export/backup workflows are not yet formalized; a structured backup feature is on the roadmap.

Are invoices mutable after creation?  
Invoices conceptually support post‑creation edits; future locking or versioning may be introduced for audit integrity.

Performance
Will the app slow down with many cases?  
Hive scales well for moderate volumes. For very large datasets, pagination and indexing optimizations are planned.

Does offline usage affect performance?  
No, offline is the default mode. External integrations may defer actions until connectivity returns.

Features
Why are ads present?  
Advertising provides an optional monetization channel; it can be disabled or tailored in future builds.

Is document scanning mandatory?  
No, it augments workflows; absence of permissions simply omits scanning capability.

Can I generate PDF invoices?  
Yes, the invoice service supports PDF generation for external sharing or record retention.

Security
Is the data encrypted locally?  
Not yet. Encryption at rest is a priority roadmap feature.

How is sensitive information protected?  
Currently through local device isolation. Future updates will add encryption, secure backup, and role‑based access.

Troubleshooting
Why does startup fail?  
Common causes include misconfigured Firebase or missing platform service initialization. Verify configuration assets.

Why are ads not loading?  
Initialization delay, incorrect ad unit configuration, or platform restrictions. Confirm ad service readiness.

Why is the invoice empty?  
Missing time entries or expenses linked to the case. Ensure entries are created prior to invoice generation.

Roadmap
When will synchronization be available?  
Cloud sync is a mid‑term objective following strengthening of authentication and data integrity safeguards.

Will there be desktop and web versions?  
Yes, responsive adaptation and platform‑specific affordances are planned enhancements.

Contribution
How can I contribute?  
Follow proposed feature branch naming, submit concise issues describing use cases, and emphasize incremental test coverage growth.

Where do I report security concerns?  
Establish a dedicated security disclosure contact (recommended: security@organization) in a future update.

Licensing
What is the license?  
No explicit license file exists yet. Adding a recognized license is recommended to clarify usage rights.

Contact
How do I request a feature?  
Open an issue or discussion thread detailing the problem solved, user impact, and measurable success criteria.

Summary
This FAQ addresses foundational inquiries; evolving capabilities will extend answers as the project matures.