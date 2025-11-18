# RoverNet PHP Backend

This directory contains the PHP JSON API backend for RoverNet.

## Overview

The PHP backend provides a simple REST-like API that stores all game data in JSON files. No database required!

## Directory Structure

```
php-backend/
├── api/                    # API endpoint files
│   ├── player_load.php    # Load player data
│   ├── player_save.php    # Save player data
│   ├── company_load.php   # Load company data
│   ├── company_save.php   # Save company data
│   └── admin_log.php      # Log admin actions
└── data/                   # JSON file storage (gitignored)
    ├── players/           # Player data files
    ├── companies/         # Company data files
    └── logs/              # Admin action logs
```

## Requirements

- PHP 7.0 or higher
- Write permissions on `data/` directory
- Apache/Nginx web server
- HTTPS recommended for production

## Installation

### Quick Setup

1. Upload the entire `php-backend` folder to your web server
2. Set permissions:
   ```bash
   chmod 755 data/
   chmod 755 data/players/
   chmod 755 data/companies/
   chmod 755 data/logs/
   ```
3. Test by visiting: `https://yourdomain.com/rovernet/api/player_load.php?userId=1`

### Detailed Setup

See [SETUP.md](../SETUP.md) in the root directory for comprehensive instructions.

## API Endpoints

### 1. player_load.php

**Purpose**: Load a player's data from storage.

**Method**: POST or GET

**Parameters**:
- `userId` (integer, required): The player's Roblox User ID

**Example Request (GET)**:
```
GET /api/player_load.php?userId=123456
```

**Example Request (POST)**:
```json
{
    "userId": 123456
}
```

**Success Response (Existing Player)**:
```json
{
    "success": true,
    "message": "Player data loaded successfully",
    "data": {
        "UserId": 123456,
        "Username": "Player123",
        "Credits": 1500,
        "CreatedAt": 1699999999,
        "UpdatedAt": 1700000000,
        "CompanyId": "cmp_1699999999_12345",
        "Flags": {
            "IsAdmin": false,
            "IsTestUser": false,
            "IsBanned": false
        }
    }
}
```

**Success Response (New Player)**:
```json
{
    "success": true,
    "message": "Player not found, ready for creation",
    "data": null
}
```

**Error Response**:
```json
{
    "success": false,
    "message": "Invalid userId provided",
    "data": null
}
```

### 2. player_save.php

**Purpose**: Save a player's data to storage.

**Method**: POST

**Request Body**:
```json
{
    "data": {
        "UserId": 123456,
        "Username": "Player123",
        "Credits": 1500,
        "CreatedAt": 1699999999,
        "UpdatedAt": 1700000000,
        "CompanyId": "cmp_1699999999_12345",
        "Flags": {
            "IsAdmin": false,
            "IsTestUser": false,
            "IsBanned": false
        }
    }
}
```

**Success Response**:
```json
{
    "success": true,
    "message": "Player data saved successfully",
    "data": {
        "userId": 123456,
        "bytesWritten": 342
    }
}
```

**Error Response**:
```json
{
    "success": false,
    "message": "Invalid or missing UserId",
    "data": null
}
```

### 3. company_load.php

**Purpose**: Load a company's data from storage.

**Method**: POST or GET

**Parameters**:
- `companyId` (string, required): The company's unique ID

**Example Request (GET)**:
```
GET /api/company_load.php?companyId=cmp_1699999999_12345
```

**Example Request (POST)**:
```json
{
    "companyId": "cmp_1699999999_12345"
}
```

**Success Response**:
```json
{
    "success": true,
    "message": "Company data loaded successfully",
    "data": {
        "CompanyId": "cmp_1699999999_12345",
        "OwnerUserId": 123456,
        "Name": "Player123 Labs",
        "CreatedAt": 1699999999,
        "UpdatedAt": 1700000000,
        "Credits": 500,
        "Domains": {
            "player123.rvn": true
        },
        "Websites": {},
        "Security": {
            "FirewallLevel": 1,
            "BotDefense": 1,
            "MalwareResistance": 1,
            "LastAttackAt": null
        }
    }
}
```

### 4. company_save.php

**Purpose**: Save a company's data to storage.

**Method**: POST

**Request Body**:
```json
{
    "data": {
        "CompanyId": "cmp_1699999999_12345",
        "OwnerUserId": 123456,
        "Name": "Player123 Labs",
        "Credits": 500,
        "Domains": {
            "player123.rvn": true
        },
        "Websites": {},
        "Security": {
            "FirewallLevel": 1,
            "BotDefense": 1,
            "MalwareResistance": 1
        }
    }
}
```

**Success Response**:
```json
{
    "success": true,
    "message": "Company data saved successfully",
    "data": {
        "companyId": "cmp_1699999999_12345",
        "bytesWritten": 458
    }
}
```

### 5. admin_log.php

**Purpose**: Log administrative actions.

**Method**: POST

**Request Body**:
```json
{
    "actorUserId": 123456,
    "targetUserId": 789012,
    "action": "ModifyCredits",
    "details": "Granted 1000 credits",
    "timestamp": 1700000000
}
```

**Success Response**:
```json
{
    "success": true,
    "message": "Admin action logged successfully",
    "data": {
        "totalLogs": 42,
        "bytesWritten": 2345
    }
}
```

## Security Features

### Input Validation

All endpoints validate:
- Required parameters are present
- Data types are correct
- UserId is a positive integer
- CompanyId contains only safe characters (alphanumeric, dash, underscore)

### File Security

- Directory traversal prevention via input sanitization
- CompanyId is sanitized: `preg_replace('/[^a-zA-Z0-9_-]/', '', $companyId)`
- File permissions should be 755 (not 777)

### CORS Headers

All endpoints include CORS headers:
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
```

**For Production**: Consider restricting `Access-Control-Allow-Origin` to specific domains.

## Data Storage

### File Naming Convention

- **Players**: `player_{UserId}.json`
  - Example: `player_123456.json`

- **Companies**: `company_{CompanyId}.json`
  - Example: `company_cmp_1699999999_12345.json`

- **Logs**: `admin_logs.json` (single file, array of log entries)

### JSON Format

All files are stored with `JSON_PRETTY_PRINT` for readability.

**Example player file** (`player_123456.json`):
```json
{
    "UserId": 123456,
    "Username": "Player123",
    "Credits": 1500,
    "CreatedAt": 1699999999,
    "UpdatedAt": 1700000000,
    "CompanyId": "cmp_1699999999_12345",
    "Flags": {
        "IsAdmin": false,
        "IsTestUser": false,
        "IsBanned": false
    }
}
```

## Error Handling

All endpoints use try-catch with `@` suppression for file operations and return structured error responses:

```json
{
    "success": false,
    "message": "Error description",
    "data": null
}
```

Common error responses:
- Invalid input parameters
- File read/write failures
- JSON decode errors
- Missing required fields

## Performance Considerations

### Scaling

For high-traffic games, consider:

1. **Caching**: Add Redis/Memcached for frequently accessed data
2. **Database Migration**: Move from JSON files to MySQL/PostgreSQL
3. **Load Balancing**: Distribute API requests across multiple servers
4. **CDN**: Use CDN for static assets

### Current Limitations

- JSON file storage is suitable for small to medium games (< 10,000 active players)
- Concurrent writes may cause race conditions
- No built-in backup mechanism

### Optimization Tips

1. **Enable PHP OpCache**:
   ```ini
   opcache.enable=1
   opcache.memory_consumption=128
   ```

2. **Use FastCGI/FPM** instead of mod_php

3. **Monitor disk I/O** on data directory

## Backup Strategy

### Manual Backup

```bash
# Backup all data
cd /path/to/rovernet
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz data/

# Restore from backup
tar -xzf backup_20231115_120000.tar.gz
```

### Automated Backup (Cron)

```bash
# Add to crontab: Daily backup at 2 AM
0 2 * * * cd /path/to/rovernet && tar -czf /backups/rovernet_$(date +\%Y\%m\%d).tar.gz data/ && find /backups -name "rovernet_*.tar.gz" -mtime +30 -delete
```

## Monitoring

### Check API Health

```bash
# Test all endpoints
curl "https://yourdomain.com/rovernet/api/player_load.php?userId=1"
curl -X POST "https://yourdomain.com/rovernet/api/player_save.php" \
  -H "Content-Type: application/json" \
  -d '{"data":{"UserId":1,"Username":"Test","Credits":1000,"CreatedAt":1700000000,"UpdatedAt":1700000000,"Flags":{}}}'
```

### Monitor Disk Usage

```bash
# Check data directory size
du -sh data/

# Count player files
ls -1 data/players/ | wc -l

# Count company files
ls -1 data/companies/ | wc -l
```

### View Admin Logs

```bash
# View recent admin actions
tail -n 50 data/logs/admin_logs.json | jq .

# Count admin actions
cat data/logs/admin_logs.json | jq 'length'
```

## Troubleshooting

### Permission Denied Errors

```bash
# Fix permissions
chmod 755 data/
chmod 755 data/players/
chmod 755 data/companies/
chmod 755 data/logs/

# Check ownership
ls -la data/
# Should be owned by web server user (www-data, apache, nginx, etc.)
```

### JSON Decode Errors

- Verify file is valid JSON: `php -r "json_decode(file_get_contents('data/players/player_123.json'));"`
- Check for corrupted files
- Restore from backup if necessary

### API Not Accessible

1. Check web server is running
2. Verify file paths are correct
3. Check `.htaccess` or Nginx config
4. Review web server error logs

## Development

### Local Testing

Use PHP's built-in server for local testing:

```bash
cd php-backend
php -S localhost:8000

# Test endpoints
curl "http://localhost:8000/api/player_load.php?userId=1"
```

### Debugging

Enable error reporting in PHP files:

```php
// Add at top of file for debugging (REMOVE in production!)
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

## Migration to Database

If you need to migrate to MySQL/PostgreSQL:

1. Create database schema matching JSON structure
2. Write migration script to import JSON files
3. Update PHP endpoints to use PDO/MySQLi
4. Test thoroughly before switching

Example schema:
```sql
CREATE TABLE players (
    user_id INT PRIMARY KEY,
    username VARCHAR(255),
    credits INT DEFAULT 0,
    created_at INT,
    updated_at INT,
    company_id VARCHAR(255),
    is_admin BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE
);
```

## License

Part of the RoverNet game project.

---

**For full setup instructions, see [SETUP.md](../SETUP.md)**
