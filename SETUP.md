# RoverNet Setup Guide

This guide walks you through setting up RoverNet from scratch.

## Prerequisites

### For PHP Backend
- Web server with PHP 7.0+ support
- Write permissions on server directories
- HTTPS enabled (recommended)
- cURL or similar for testing

### For Roblox
- Roblox Studio installed
- Basic understanding of Roblox Studio
- HttpService access enabled

## Step-by-Step Setup

### Part 1: PHP Backend Deployment

#### Option A: Using cPanel/File Manager

1. **Login to your web hosting control panel**

2. **Navigate to File Manager**

3. **Create directory structure**:
   ```
   public_html/
   └── rovernet/
       ├── api/
       └── data/
           ├── players/
           ├── companies/
           └── logs/
   ```

4. **Upload PHP files**:
   - Upload all files from `php-backend/api/` to `rovernet/api/`
   - Files to upload:
     - player_load.php
     - player_save.php
     - company_load.php
     - company_save.php
     - admin_log.php

5. **Set directory permissions**:
   - Right-click on `rovernet/data` → Change Permissions → Set to `755`
   - Do the same for `players/`, `companies/`, and `logs/` subdirectories

6. **Test the API**:
   - Visit: `https://yourdomain.com/rovernet/api/player_load.php?userId=1`
   - Should see JSON response:
     ```json
     {
       "success": true,
       "message": "Player not found, ready for creation",
       "data": null
     }
     ```

#### Option B: Using FTP/SFTP

1. **Connect to your server** using FileZilla or similar FTP client

2. **Upload files**:
   ```
   Local: /path/to/RoverNet/php-backend/
   Remote: /public_html/rovernet/
   ```

3. **Create data directories** if not present:
   ```bash
   mkdir -p data/players
   mkdir -p data/companies
   mkdir -p data/logs
   ```

4. **Set permissions via SSH** (if available):
   ```bash
   chmod 755 data/
   chmod 755 data/players/
   chmod 755 data/companies/
   chmod 755 data/logs/
   ```

#### Option C: Using Command Line (VPS/Dedicated)

1. **SSH into your server**

2. **Navigate to web root**:
   ```bash
   cd /var/www/html  # or your web root
   ```

3. **Create directory and upload files**:
   ```bash
   mkdir -p rovernet/api rovernet/data/{players,companies,logs}
   ```

4. **Upload files** (using SCP, git, or rsync):
   ```bash
   # Example using git
   git clone https://github.com/YourRepo/RoverNet.git
   cp -r RoverNet/php-backend/* rovernet/
   ```

5. **Set ownership and permissions**:
   ```bash
   chown -R www-data:www-data rovernet/data
   chmod -R 755 rovernet/data
   ```

6. **Configure Apache/Nginx** (if needed):
   
   **Apache (.htaccess in rovernet/api/)**:
   ```apache
   <IfModule mod_rewrite.c>
       RewriteEngine On
       RewriteBase /rovernet/api/
   </IfModule>
   
   # Security headers
   Header set Access-Control-Allow-Origin "*"
   Header set Access-Control-Allow-Methods "POST, GET, OPTIONS"
   Header set Access-Control-Allow-Headers "Content-Type"
   ```

   **Nginx (in server block)**:
   ```nginx
   location /rovernet/api/ {
       add_header Access-Control-Allow-Origin *;
       add_header Access-Control-Allow-Methods "POST, GET, OPTIONS";
       add_header Access-Control-Allow-Headers "Content-Type";
   }
   ```

7. **Test the API**:
   ```bash
   curl "https://yourdomain.com/rovernet/api/player_load.php?userId=1"
   ```

### Part 2: Roblox Game Setup

#### Step 1: Create/Open Roblox Place

1. **Open Roblox Studio**

2. **Create new place** or open existing:
   - File → New
   - Choose a template (any will work)

#### Step 2: Enable HttpService

1. **Open Game Settings**:
   - Home tab → Game Settings button
   - Or press Alt+S

2. **Enable HTTP**:
   - Navigate to Security section
   - Check "Allow HTTP Requests"
   - Click Save

#### Step 3: Create Folder Structure

1. **In Explorer panel**, create this structure:
   ```
   ReplicatedStorage/
   └── RoverNetShared (ModuleScript)
   
   ServerScriptService/
   └── RoverNetServer (Folder)
       ├── MainServer (Script)
       ├── Config (ModuleScript)
       ├── ApiService (ModuleScript)
       ├── LoggingService (ModuleScript)
       ├── PlayerDataStore (ModuleScript)
       ├── EconomyService (ModuleScript)
       ├── CompanyService (ModuleScript)
       ├── WebsiteService (ModuleScript)
       ├── SecurityService (ModuleScript)
       ├── TaskService (ModuleScript)
       └── AdminService (ModuleScript)
   
   StarterPlayer/
   └── StarterPlayerScripts/
       └── RoverNetClient (LocalScript)
   ```

#### Step 4: Copy Script Content

1. **For each script/module**:
   - Right-click folder → Insert Object → Choose type (Script/ModuleScript/LocalScript)
   - Rename to match the file name
   - Open the script in Studio
   - Copy content from corresponding `.lua` file
   - Paste into Studio script
   - Save

2. **Important naming**:
   - `MainServer` must be a **Script** (not LocalScript)
   - All `*Service` and `Config` must be **ModuleScript**
   - `RoverNetShared` must be **ModuleScript**
   - `RoverNetClient` must be **LocalScript**

#### Step 5: Configure API URL

1. **Open Config module**:
   - Navigate to: ServerScriptService → RoverNetServer → Config

2. **Edit API_BASE_URL**:
   ```lua
   Config.API_BASE_URL = "https://yourdomain.com/rovernet/api"
   ```
   Replace `yourdomain.com` with your actual domain.

3. **Add your User ID as admin**:
   - Find your Roblox User ID (visit your profile, check URL)
   - Add to ADMINS table:
     ```lua
     Config.ADMINS = {
         [YOUR_USER_ID_HERE] = true,
     }
     ```

#### Step 6: Test the Game

1. **Press F5** or click Play button

2. **Check for UI**:
   - You should see the HUD bar at top
   - Bottom buttons: "📋 Tasks", "🌐 Websites"
   - If admin: "⚙️ Admin" button in top right

3. **Check Output console** (View → Output):
   - Should see: `[LoggingService] Initialized`
   - Should see: `=== RoverNet Server Starting ===`
   - Should see: `=== RoverNet Server Ready ===`
   - Should NOT see any errors

4. **Test functionality**:
   - Click "📋 Tasks" → Complete a task
   - Check if credits increase
   - Click "🌐 Websites" → Create a website
   - If admin: Check admin panel

### Part 3: Troubleshooting Common Issues

#### Issue: "API: Error" in game

**Possible causes:**
1. HttpService not enabled
2. Wrong API URL in Config
3. Server not accessible
4. PHP errors

**Solutions:**
```lua
-- 1. Verify HttpService in Game Settings

-- 2. Check Config.lua has correct URL:
Config.API_BASE_URL = "https://yourdomain.com/rovernet/api"

-- 3. Test API manually:
-- Visit in browser: https://yourdomain.com/rovernet/api/player_load.php?userId=1

-- 4. Enable debug mode:
Config.DEBUG_MODE = true

-- 5. Temporarily disable API for local testing:
Config.ENABLE_API_SAVING = false
```

#### Issue: PHP errors on server

**Check PHP error logs**:
```bash
# On Linux
tail -f /var/log/apache2/error.log
# or
tail -f /var/log/nginx/error.log

# Using cPanel: Go to Error Log viewer
```

**Common fixes**:
```bash
# Ensure directories exist
ls -la rovernet/data/

# Fix permissions
chmod 755 rovernet/data/
chmod 755 rovernet/data/players/
chmod 755 rovernet/data/companies/
chmod 755 rovernet/data/logs/

# Check PHP syntax
php -l rovernet/api/player_load.php
```

#### Issue: UI not appearing

**Solutions:**
1. Check all scripts are in correct locations
2. Verify RoverNetShared is in ReplicatedStorage
3. Check Output console for errors
4. Make sure MainServer is running (should be a Script, not LocalScript)

#### Issue: Player data not saving

**Check:**
1. Directory permissions (must be writable)
2. PHP error logs
3. Enable Config.DEBUG_MODE
4. Verify API URL is correct and accessible

### Part 4: Going Live

#### Pre-Launch Checklist

- [ ] API endpoint is using HTTPS
- [ ] All admin User IDs are configured
- [ ] Config values are production-ready
- [ ] Directory permissions are secure (755, not 777)
- [ ] Tested with multiple players
- [ ] Admin panel works correctly
- [ ] Economy is balanced
- [ ] Debug mode is disabled (`Config.DEBUG_MODE = false`)

#### Publishing to Roblox

1. **Save your place**:
   - File → Publish to Roblox
   - Choose "Create new game" or update existing

2. **Configure game settings**:
   - Go to game configuration page
   - Set name, description, icon
   - Set genre and other metadata

3. **Enable HttpService** (if not already):
   - Settings → Security → Allow HTTP Requests

4. **Make game public**:
   - Settings → Access → Public

#### Monitoring

1. **Check admin logs regularly**:
   - Access: `rovernet/data/logs/admin_logs.json`
   - Review for suspicious activity

2. **Monitor server logs**:
   - Check PHP error logs
   - Monitor disk usage in data directories

3. **In-game monitoring**:
   - Use Admin Panel to check players
   - Watch Output console for errors
   - Enable DEBUG_MODE temporarily if issues arise

## Next Steps

After setup:

1. **Customize the game**:
   - Adjust costs and rewards in Config.lua
   - Add new tasks
   - Create custom security events

2. **Extend functionality**:
   - Add new features to services
   - Create new UI panels
   - Add new admin commands

3. **Optimize**:
   - Monitor performance
   - Adjust auto-save intervals
   - Balance economy based on player feedback

## Support

If you encounter issues:

1. Check the main README.md
2. Review Output console in Studio
3. Check PHP error logs on server
4. Enable DEBUG_MODE for detailed logs

---

**You're all set! Enjoy building your RoverNet empire! 🚀**
