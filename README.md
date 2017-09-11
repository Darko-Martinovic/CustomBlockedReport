# T-SQL & SQLCLR solution. Building Custom Blocked Process Report

Practical solution which will tell you, almost immediately by sending an e-mail, when blocking occurs. 

# The solution include 

- BPR.GetResourceName T-SQL scalar function which takes waitresource as parametar and return what is the subject of blocking
- BPR.GetResourceContent T-SQL scalar function which takes waitresource and resource name as parameters and return what is content of blocking in form of XML document. 
