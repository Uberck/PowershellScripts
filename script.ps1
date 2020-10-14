#Script to remove user permissions from folder/subfolder - Christos Kokkalis

$user = Read-Host -Prompt 'Input domain/user'
$folders = Read-Host -Prompt 'Input directory (C:\directory)'   #Can also enter list, ie - "C:\directory","C:\directory\subDir"

#Removes inherited permission from top folders and child objects
Foreach($folder in $folders) { 
 icacls $folder /inheritance:d
 Get-ChildItem -Path $folder -Recurse | Where-Object{$_.PSisContainer} | ForEach-Object {$subfolder = $_.FullName; icacls $subfolder /inheritance:d}
}
#Remove User from parent objects
$acls = Get-Acl -path $folders 
Foreach($acl in $acls) { 
 $folder = (convert-path $acl.pspath)
   Foreach($access in $acl.access) { 
   Foreach($value in $access.identityReference.Value) {
    if ($value -eq $user) { 
     $acl.RemoveAccessRule($access)
} } }
 Set-Acl -path $folder -aclObject $acl 
}
#Remove User from child objects
Foreach($folder in $folders) { 
Get-ChildItem -Path $folder -Recurse | ForEach-Object {$object = $_.FullName; 
 $acls = Get-Acl -Path $_.FullName; 
 foreach ($acl in $acls) {
  foreach ($access in $acl.Access) {
   foreach ($value in $access.IdentityReference.Value) {
    if ($value -eq $user) {
     $acl.RemoveAccessRule($access)
} } } }
Set-Acl -path $object -aclObject $acl
} }
#Inherit set permissions on Child objects
Foreach($folder in $folders) { 
Get-ChildItem -Path $folder -Recurse | Where-Object{$_.PSisContainer} | ForEach-Object {$subfolder = $_.FullName; icacls $subfolder /inheritance:e}
}