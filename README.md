# taxiShare

### Prerequisites :
1. Download the latest config file form https://console.firebase.google.com/project/dshare-ac2cb/settings/general/ios:com.Dshare
2. Install cocaPods https://cocoapods.org/

### Get Started :
1. git clone https://github.com/valems92/taxiShare.git
2. open project in xCode: doubleclick on taxiShare.xcworkspace file
4. pod install
5. Put the config file (GoogleService-Info.plist) under taxiShare/taxiShare folder

Sometimes xcode can't see files that are physically exist, so you have to add them to your project at right click on the project -> Add Files To "taxiShare"

### work with branches + git comands:
Once you want to push yuor changes, push it first to a new branch and then merge it to master (to avoid problems).  
Make sure you are on Master before creating a branch.  
**Don't forget to pull changes before you start working on your new feature: git pull**

#### Create new branch
1. git branch (Verify you are on branch master)
2. git branch <branch_name> (Creates a new branch)
3. git checkout <branch_name> (Switch to the new branch)
4. git status  (Verify you are on your new branch)

#### Push changes to new branch
1. git add . (Add chages to stage)
2. git commit -m"commit_msg" (Commit changes)
3. git push origin <branch_name> (Push to branch)

#### git merge to master
1. git checkout master (Switch to master branch)
2. git merge <branch_name> (marge you changes to master)
3. git push origin master (Push to master)
4. git branch -D <branch_name> (Delete new branch)

Example: https://www.youtube.com/watch?v=uR-9NGrpU-c
