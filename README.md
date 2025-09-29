# 🖥️ Windows System Health & Security Monitoring Script

This project is a **PowerShell-based monitoring tool** developed as part of **INFO33192 Lab 1**.  
It performs **system health checks**, **automated remediation**, and **security event monitoring** on a Windows environment.  

Author: **Majd Abboud**  
Student ID: **991589924**

---

## ✨ Features

### 🔧 System Health Monitoring
- **CPU Usage**  
  - Logs a warning if CPU > 80% for more than 30 seconds.  
  - Terminates high-usage processes if sustained for 1 minute.

- **Memory Usage**  
  - Logs a warning if memory usage exceeds 85%.

- **Disk Space**  
  - Logs a critical alert if free space on `C:` falls below 15%.  
  - Automatically deletes files in `C:\Temp` and logs space freed.

---

### 🔐 Security Event Monitoring
- Detects and logs:  
  - Multiple failed login attempts  
  - Account lockouts  
  - Unexpected service stops (e.g., Print Spooler)

- Writes all detections into a **custom Event Log source**:  
  `Lab1-Monitoring`

---

## 📂 Project Files

```
Lab_Project/
├── Lab_Code.ps1              # PowerShell script
├── Lab(evidence_logs).txt    # Execution logs & outputs
├── Lab_Report.docx           # Formal lab report & reflection
```

---

## ⚙️ Usage

1. **Run the script** in PowerShell (with admin privileges):  
   ```powershell
   .\Lab_Code.ps1
   ```

2. **Logs generated**:  
   - System health alerts  
   - Security alerts  
   - Remediation actions (terminated processes, cleared temp files)

3. **Event Viewer Integration**:  
   All alerts also appear under `Windows Logs > Application > Lab1-Monitoring`.

---

## 📝 Example Logs

```
2025-09-24 21:49:12 - Part 2: CPU >80% for 30s — please take action (close heavy apps, check Task Manager).
2025-09-24 21:49:12 - Part 3: terminating HeavyLoad (PID 3760) — >80% for ~1 minute
2025-09-24 21:50:45 - Part 2: WARNING — memory >85% (93.70 %)
2025-09-24 21:50:45 - Part 2: CRITICAL — C: free <15% (5.52 %)
2025-09-24 21:50:45 - Part 3: deleted C:\Temp, freed about 35 GB
2025-09-24 21:52:16 - Part 4: [SECURITY ALERT] Multiple failed login attempts detected for user: majd
2025-09-24 21:52:16 - Part 4: [SECURITY ALERT] Account lockout detected for user: majd
2025-09-24 21:52:16 - Part 4: [SECURITY ALERT] Unexpected service stop: Print Spooler
```

---

## 🔒 Reflection (from Lab Report)

- Logging **both health and security events** ensures complete visibility—investigations aren’t slowed down by missing context.  
- If **remediation isn’t logged**, attackers could exploit the same issue again, and audits would lack accountability.  
- Applying **least privilege** limits script permissions, reducing the attack surface if the script is hijacked.  

---

## 📜 License

This project was developed for **academic purposes** under Sheridan College coursework.  
Use and modification allowed for learning, research, and demonstration.
