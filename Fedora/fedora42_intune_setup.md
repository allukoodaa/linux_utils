
# Microsoft Intune + Edge Setup on Fedora 42

> _Tested on Fedora 42 (Workstation)_

---

## 🔹 1. Import Microsoft GPG Key

```
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
```

---

## 🔹 2. Add Microsoft’s RHEL 9.0 Prod Repository

```
sudo dnf config-manager addrepo --from-repofile=https://packages.microsoft.com/yumrepos/microsoft-rhel9.0-prod/config.repo
```

> 🔸 NOTE: The crucial fix is **adding `/config.repo`** to the URL — this gets the proper `.repo` file, not just the base package directory.

---

## 🔹 3. Install Java 11 via Adoptium (Microsoft-intune dependency)

Fedora 42 no longer ships `java-11-openjdk`, so we need to use the **Adoptium (Temurin) repo**.

```
sudo dnf install -y adoptium-temurin-java-repository
sudo dnf config-manager setopt adoptium-temurin-java-repository.enabled=1
sudo dnf install -y temurin-11-jdk
```

> 🔸 This satisfies `microsoft-identity-broker`, a required dependency of `intune-portal`.

---

## 🔹 4. Install the Intune Client

```
sudo dnf install -y intune-portal
```

> 🔸 This will now work without dependency conflicts after Java 11 is installed from Adoptium.

---

## 🔹 5. Install Microsoft Edge (manually from RPM)

```
wget https://packages.microsoft.com/yumrepos/edge/microsoft-edge-stable-138.0.3351.95-1.x86_64.rpm
sudo dnf install -y microsoft-edge-stable-138.0.3351.95-1.x86_64.rpm
```

> 🔸 Edge is required for GUI-based Intune compliance workflows and Microsoft login flows.

---

## Post-Install Notes

- Launch the Intune Portal:

```
intune-portal
```

- Login via Microsoft Entra ID (your work credentials)
- Your device should now be enrolled and visible in Microsoft Endpoint Manager

- Disable adoptium and RHEL repos to avoid future conflicts when installing tools using `dnf`

```
sudo dnf config-manager setopt microsoft-rhel9.0-prod-yum.enabled=0
sudo dnf config-manager setopt adoptium-temurin-java-repository.enabled=0
```

---

## 🧾 TL;DR Summary

| Component              | Source                                  |
|------------------------|------------------------------------------|
| `intune-portal`        | Microsoft RHEL 9 prod repo               |
| Java 11 (JDK)          | Adoptium Temurin                         |
| Microsoft Edge         | Direct RPM download                      |

---
