# 🚀 Quick Start - Local Cricket API

## Start Your Cricket App in 2 Steps

### Step 1: Start the Server
```powershell
cd scarpy
.\start_server.bat
```
✅ Server runs on: `http://localhost:8000`

### Step 2: Run Flutter App
```powershell
flutter run
```
✅ App automatically connects to your local server!

---

## ✅ What's Changed?

Your app now uses **YOUR scrapped data** from `cleaned_cricket_data.json` instead of external APIs!

---

## 🔍 Quick Check

### Is the server running?
```powershell
curl http://localhost:8000/health
```

### View all matches:
```powershell
curl http://localhost:8000/api/v1/matches
```

### View live matches:
```powershell
curl http://localhost:8000/api/v1/matches/live
```

### View API documentation:
Open browser: `http://localhost:8000/docs`

---

## 📊 Server Status

Check server statistics:
```powershell
curl http://localhost:8000/api/v1/status
```

Response shows:
- Is server running
- Last update time
- Total matches
- Live matches count

---

## 🛑 Stop the Server

Press `Ctrl+C` in the terminal running the server

---

## 🆘 Troubleshooting

### App shows no data?
1. Check if server is running: `curl http://localhost:8000/health`
2. Check server terminal for errors
3. Check Flutter console for error logs

### Server won't start?
1. Check if port 8000 is free: `netstat -ano | findstr :8000`
2. Activate virtual environment manually:
   ```powershell
   cd scarpy
   .\myenv\Scripts\activate
   python cricket_server.py
   ```

### Data not updating?
Manually trigger refresh:
```powershell
curl -X POST http://localhost:8000/api/v1/refresh
```

---

## 📝 Files Modified

1. ✅ `lib/core/constants/api_constants.dart` - Points to localhost:8000
2. ✅ `lib/feature/matches_scores/data/source/data_source.dart` - Uses local server
3. ✅ `lib/feature/matches_scores/data/repository/match_repository_Impl.dart` - Enhanced logging
4. ✅ `lib/feature/matches_scores/presentation/providers/matches_provider.dart` - Prioritizes local server

---

## 🎯 Key Benefits

✅ No API limits  
✅ No API costs  
✅ Full control of data  
✅ Instant updates (every 10 seconds)  
✅ Works offline (fallback to JSON file)  

---

For detailed documentation, see: `LOCAL_API_INTEGRATION.md`
