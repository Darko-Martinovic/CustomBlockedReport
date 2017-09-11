# T-SQL & SQLCLR solution. Building Custom Blocked Process Report

Practical solution which will tell you, almost immediately by sending an e-mail, when blocking occurs. 

# The solution include 

- BPR.GetResourceName T-SQL scalar function which returns what is subject of blocking. Usually this means table or index name.
- BPR.GetResourceContent T-SQL scalar function which returns the content of the blocked resource in form of XML document. 
- BPR.GetWaitInfo T-SQL table valued function which returns the blocked process chain as a table. On the top there is a root blocker. 
- BPR.GetLockInfo T-SQL table valued function which returns table that displays locks acquired by a session. 
- BPR.GetResourceNameCLR SQLCLR equivalent to T-SQL function BPR.GetResourceName. 
- BPR.GetResourceContentCLR SQLCLR equivalent to T-SQL function BPR.GetResourceContent.
- BPR.HandleBpr Stored procedure that responds to blocked process events.
- BPR.ShowBlocking Stored procedure that displays for each block the blocking tree.
