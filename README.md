# 🌐 RoverNet

**A Fictional Internet Simulator Game for Roblox**

RoverNet is a creative, educational Roblox game where players build and manage virtual companies that run in-game websites, domains, and digital services in a purely fictional cyberspace. Players can create websites, manage security, complete tasks for credits, and engage with a fantasy internet economy.

## ⚠️ Important Safety Notice

RoverNet is a **FICTIONAL GAME** and does NOT teach or simulate real-world hacking:
- All "hacking" mechanics are **abstract minigames and puzzles**
- All security events are **fictional game mechanics** (bot swarms, glitch storms, etc.)
- **NO real hacking techniques** are used or taught
- **NO real-world security protocols** are simulated
- All interactions are **purely within the game**

## 🎮 Game Features

### Core Gameplay
- **Company Management**: Create and run your own virtual tech company
- **Website Creation**: Build websites on custom domains (*.rvn)
- **SSL & Security**: Manage fictional security levels and defend against game attacks
- **Task System**: Complete jobs to earn Credits (in-game currency)
- **Economy**: Buy upgrades, create websites, and expand your business

### Security & Defense (Fictional)
- Defend websites against fictional attacks:
  - Bot Swarms
  - Glitch Storms
  - Corruption Events
  - Data Goblins
- Upgrade security stats:
  - Firewall Level
  - Bot Defense
  - Malware Resistance

### Admin Features
- Monitor online players
- Adjust player credits
- Trigger test security events
- Full logging system

## 📁 Repository Structure

```
RoverNet/
├── php-backend/          # PHP JSON API Backend
│   ├── api/             # API endpoints
│   │   ├── player_load.php
│   │   ├── player_save.php
│   │   ├── company_load.php
│   │   ├── company_save.php
│   │   └── admin_log.php
│   └── data/            # JSON file storage
│       ├── players/     # Player data files
│       ├── companies/   # Company data files
│       └── logs/        # Admin logs
│
└── roblox/              # Roblox Game Code (Luau)
    ├── ReplicatedStorage/
    │   └── RoverNetShared.lua        # Shared utilities & types
    ├── ServerScriptService/
    │   └── RoverNetServer/
    │       ├── MainServer.lua        # Main server script
    │       ├── Config.lua            # Configuration
    │       ├── ApiService.lua        # HTTP API wrapper
    │       ├── LoggingService.lua    # Logging system
    │       ├── PlayerDataStore.lua   # Player data management
    │       ├── EconomyService.lua    # Credits & economy
    │       ├── CompanyService.lua    # Company management
    │       ├── WebsiteService.lua    # Website operations
    │       ├── SecurityService.lua   # Security events
    │       ├── TaskService.lua       # Task system
    │       └── AdminService.lua      # Admin commands
    └── StarterPlayer/
        └── StarterPlayerScripts/
            └── RoverNetClient.lua    # Client UI & logic
```

## 🚀 Quick Start

### 1. PHP Backend Setup

1. **Upload PHP files** to your web server:
   ```bash
   # Upload the entire php-backend folder to your web server
   # Example structure:
   /your-domain.com/rovernet/api/
   /your-domain.com/rovernet/data/
   ```

2. **Set permissions** on data directories:
   ```bash
   chmod 755 php-backend/data
   chmod 755 php-backend/data/players
   chmod 755 php-backend/data/companies
   chmod 755 php-backend/data/logs
   ```

3. **Verify API** by accessing:
   ```
   https://your-domain.com/rovernet/api/player_load.php?userId=1
   ```
   Should return JSON response.

### 2. Roblox Setup

1. **Create a new Roblox Place** or open existing one

2. **Enable HttpService**:
   - In Roblox Studio: Home → Game Settings → Security
   - Enable "Allow HTTP Requests"

3. **Import all Luau scripts**:
   - Copy files from `roblox/` folder into your place
   - Maintain the exact folder structure shown above

4. **Configure API URL**:
   - Open `ServerScriptService.RoverNetServer.Config`
   - Change `API_BASE_URL` to your server URL:
     ```lua
     Config.API_BASE_URL = "https://your-domain.com/rovernet/api"
     ```

5. **Set Admin IDs**:
   - In `Config.lua`, add your Roblox User ID:
     ```lua
     Config.ADMINS = {
         [YOUR_USER_ID] = true,
     }
     ```

6. **Test the game**:
   - Press F5 to start testing
   - You should see the RoverNet UI appear
   - Check the output console for any errors

## ⚙️ Configuration

### Config.lua Settings

Key configuration options in `ServerScriptService.RoverNetServer.Config`:

```lua
-- API Configuration
Config.API_BASE_URL = "https://example.com/rovernet/api"
Config.ENABLE_API_SAVING = true  -- Set to false for local testing

-- Economy
Config.DEFAULT_STARTING_CREDITS = 1000
Config.DEFAULT_COMPANY_CREDITS = 500

-- Costs
Config.COSTS = {
    CREATE_WEBSITE = 100,
    CREATE_PAGE = 50,
    INCREASE_SSL = 200,
    UPGRADE_FIREWALL = 300,
}

-- Task Rewards
Config.TASK_REWARDS = {
    DeliverData = 50,
    ProcessLogs = 75,
    PatchServer = 100,
}

-- Limits
Config.MAX_WEBSITES_PER_COMPANY = 10
Config.MAX_PAGES_PER_WEBSITE = 20
Config.MAX_ELEMENTS_PER_PAGE = 50
```

## 🎯 How to Play

### For Players

1. **Join the game** - You'll start with 1000 Credits
2. **Complete tasks** - Click the "📋 Tasks" button to earn credits
3. **Create websites**:
   - Click "🌐 Websites" button
   - Click "+ Create Website"
   - Enter a domain name (must end in .rvn)
   - Enter a website title
4. **Upgrade security** - Increase SSL levels to protect your sites
5. **Defend against attacks** - Respond to bot swarms and corruption events

### For Admins

1. **Access Admin Panel** - Click "⚙️ Admin" button (top right)
2. **View players** - Click "🔄 Refresh Players"
3. **Modify credits** - Enter delta amount and click "Apply"
4. **Trigger test attacks** - Test security mechanics

## 🔧 API Reference

### PHP Endpoints

#### POST/GET `player_load.php`
Load player data by UserId.

**Request:**
```json
{
    "userId": 123456
}
```

**Response:**
```json
{
    "success": true,
    "message": "Player data loaded successfully",
    "data": {
        "UserId": 123456,
        "Username": "Player123",
        "Credits": 1000,
        ...
    }
}
```

#### POST `player_save.php`
Save player data.

**Request:**
```json
{
    "data": {
        "UserId": 123456,
        "Username": "Player123",
        "Credits": 1500,
        ...
    }
}
```

#### POST/GET `company_load.php`
Load company data by CompanyId.

#### POST `company_save.php`
Save company data.

#### POST `admin_log.php`
Log admin actions.

## 📊 Data Models

### PlayerData
```lua
{
    UserId: number,
    Username: string,
    Credits: number,
    CreatedAt: number,
    UpdatedAt: number,
    CompanyId: string?,
    Flags: {
        IsAdmin: boolean?,
        IsTestUser: boolean?,
        IsBanned: boolean?,
    }
}
```

### CompanyData
```lua
{
    CompanyId: string,
    OwnerUserId: number,
    Name: string,
    CreatedAt: number,
    UpdatedAt: number,
    Credits: number,
    Domains: { [string]: boolean },
    Websites: { [string]: WebsiteData },
    Security: SecurityStats,
}
```

### WebsiteData
```lua
{
    WebsiteId: string,
    Domain: string,
    Title: string,
    Pages: { [string]: PageData },
    SSLLevel: number,
    TrafficScore: number,
    Health: number,
}
```

## 🐛 Troubleshooting

### "API: Error" Status
- Check if HttpService is enabled in Game Settings
- Verify API_BASE_URL is correct in Config.lua
- Check web server is accessible
- Check PHP error logs

### Player Data Not Saving
- Verify data directory permissions (755)
- Check PHP error logs
- Enable Config.DEBUG_MODE for detailed logs

### UI Not Appearing
- Check Output console for errors
- Verify all scripts are in correct locations
- Check ReplicatedStorage.RoverNetShared exists
- Verify RemoteEvents are created

## 🔐 Security Best Practices

1. **Never expose real API keys** or passwords in the game
2. **Validate all inputs** server-side (already implemented)
3. **Use HTTPS** for your API endpoint
4. **Set proper file permissions** on the server
5. **Monitor admin logs** regularly
6. **Keep backups** of player/company data

## 📝 License

This is a game project. Please ensure compliance with Roblox Terms of Service when deploying.

## 🤝 Contributing

This is a complete implementation. To extend:

1. Add new tasks in Config.TASK_REWARDS
2. Add new security events in SecurityService
3. Create new UI panels in RoverNetClient
4. Add new API endpoints as needed

## 📧 Support

Check the Output console in Roblox Studio for detailed error messages and logs.

---

**Remember: RoverNet is purely fictional entertainment. It does NOT teach or simulate real hacking!**
