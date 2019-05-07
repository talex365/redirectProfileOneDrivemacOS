Readme file for redirectProfileONeDrivemacOS.sh
created by Jon Oregon 10/29/18
Released on use at own risk basis

This script moves user profile folders Desktop, Documents, and Pictures to OneDrive, then symlinks them back to
the home folder, backing user data up to OneDrive automatically. The script is designed to work with
jamf pro, either as part of enrollment or as a standalone policy available through self service.

Notes on use:

-Assumes using Office365 enterprise subscription with specified org names
-Assumes default locations on app install, sync directory path. Suggest having these configured through jamf
-script will check for OneDrive install, if not detected will prompt user to install, take to self service install
location, and wait for 10 minutes
-script will check for sync directory location, if not detected will prompt user to sign into OneDrive and configure, 
will wait 10 minutes
-script will check for duplicates when moving data from home folders to OneDrive from directory root, if duplicates
are found, will move to a temporary directory at user home, log changes, and notify user to rectify manually
