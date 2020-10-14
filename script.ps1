#Script to remove user permissions from folder/subfolder - Christos Kokkalis 2020

$user = Read-Host -Prompt 'Input domain/user'
$folders = Read-Host -Prompt 'Input directory (C:\directory)' #Can also enter list, ie - "C:\directory","C:\directory\subDir"

#Removes inherited permission from top folders and child objects
foreach ($folder in $folders)
{
  icacls $folder /inheritance:d
  Get-ChildItem -Path $folder -Recurse | Where-Object { $_.PSIsContainer } | ForEach-Object
  {
    $subfolder = $_.FullName; icacls $subfolder /inheritance:d
  }
}

#Remove User from parent objects
$acls = Get-Acl -Path $folders
foreach ($acl in $acls)
{
  $folder = (Convert-Path $acl.PSPath)
  foreach ($access in $acl.access)
  {
    foreach ($value in $access.identityReference.Value)
    {
      if ($value -eq $user)
      {
        $acl.RemoveAccessRule($access)
      }
    }
  }
  Set-Acl -Path $folder -AclObject $acl
}

#Remove User from child objects
foreach ($folder in $folders)
{
  Get-ChildItem -Path $folder -Recurse | ForEach-Object
  {
    $object = $_.FullName;
    $acls = Get-Acl -Path $_.FullName;
    foreach ($acl in $acls)
    {
      foreach ($access in $acl.access)
      {
        foreach ($value in $access.identityReference.Value)
        {
          if ($value -eq $user)
          {
            $acl.RemoveAccessRule($access)
          }
        }
      }
    }

    Set-Acl -Path $object -AclObject $acl
  }
}

#Inherit set permissions on child objects
foreach ($folder in $folders) {
  Get-ChildItem -Path $folder -Recurse | Where-Object { $_.PSIsContainer } | ForEach-Object { $subfolder = $_.FullName; icacls $subfolder /inheritance:e
  }
}

cmd /c 'pause' #added pause for running outside of console
