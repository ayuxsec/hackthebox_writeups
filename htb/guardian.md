1. found port 80 open
2. student portal redirected to `portal.guardian.htb`
3. only provides password but not the username in help 
4. however in testionimal you could try the user ids of given user and login
5. idor allowed viewing other chats `http://portal.guardian.htb/student/chat.php?chat_users[0]=1&chat_users[1]=2`
6. captured request in burpsuite -> send to intruder -> mark both fields -> payload type number -> attack type cluster bomb -> -ve filter `Content-Length: 5761`
7. Here is your password for gitea: DHsNnk3V50 in chat leaked jamil.enockson password by admin
8. added to host `echo $target_ip gitea.guardian.htb | sudo tee -a /etc/hosts`
9. on http://gitea.guardian.htb/user/login: jamil.enockson failed but jamil worked for username and previously leaked password.
10. http://gitea.guardian.htb/Guardian/portal.guardian.htb reveals source code of `portal.guardian.htb`
11. composer.json file in root of repo reveals portal.guard... is running a vulnerable version of phpspreadsheet which is vulnerable to xss

```json
{
    "require": {
        "phpoffice/phpspreadsheet": "3.7.0",
        "phpoffice/phpword": "^1.3"
    }
}
```

12. from reading advisories https://github.com/PHPOffice/PhpSpreadsheet/security/advisories/GHSA-79xx-vf93-p7cx the vulnerable fn is `generateHTMLAll`
13. from search we find a view files having that function but only 1 file however `view-submission.php` seems to be using the vulnerable php module `require '../vendor/autoload.php'; // Include PHPOffice PHP Spreadsheet` and the name also suggests it's used to view submission submitted by students so the xlsx file could be user controllable
14. http://portal.guardian.htb/student/assignments.php allows to submit submission
