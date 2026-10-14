# Esportare per Android e iOS

Il progetto usa il renderer **GL Compatibility**, che è il più compatibile con i telefoni.
La risoluzione interna è 320×180, scalata a pixel interi. In orizzontale l'area si allarga per riempire gli schermi 18:9 e 20:9.
Il file `export_presets.cfg` contiene già i preset "Android" e "iOS".

Prima di tutto installa i template di esportazione: **Editor → Gestisci template di esportazione → Scarica e installa** (stessa versione, 4.3).

## Android

1. Installa **JDK 17** e l'**Android SDK** (basta Android Studio oppure i command-line tools).
2. In **Editor → Impostazioni editor → Export → Android** imposta:
   - `Java SDK Path`
   - `Android SDK Path`
3. Crea una keystore di release (non metterla nel repository):
   ```bash
   keytool -genkeypair -v -keystore rosanf-release.keystore -alias rosanf \
     -keyalg RSA -keysize 2048 -validity 10000
   ```
4. **Progetto → Esporta → Android**:
   - In *Keystore → Release* indica il file, l'alias e la password.
   - Il package è `it.rosanf.gioco`. Cambialo se ti serve, ma deve essere unico sul Play Store.
   - Per un APK di prova lascia `Use Gradle Build` disattivato.
   - Per il **Play Store** serve un **AAB**: attiva `Gradle Build`, esegui *Progetto → Installa template di build Android* e imposta `Export Format = AAB`.
5. Premi *Esporta progetto*. Per provare al volo su un telefono collegato via USB con il debug attivo, usa l'icona Android in alto a destra nell'editor.

Da riga di comando:

```bash
godot --headless --path . --export-release "Android" build/android/rosanf.apk
```

## iOS

Serve un **Mac** con **Xcode** e un account **Apple Developer**.

1. **Progetto → Esporta → iOS**:
   - `App Store Team ID`: il Team ID del tuo account developer.
   - `Bundle Identifier`: `it.rosanf.gioco` (o il tuo).
   - Icona App Store 1024×1024: aggiungi un PNG (puoi ingrandire `icon.png` a pixel interi).
2. Esporta. Godot crea un progetto Xcode (`.xcodeproj`).
3. Apri il progetto in Xcode, scegli il dispositivo o *Any iOS Device*, poi **Product → Archive** e carica su App Store Connect / TestFlight.

## Pubblicazione: contenuti per adulti

- **Google Play:** compila il questionario di classificazione IARC in modo onesto. Il gioco mostra alcol, droghe, violenza e sesso implicito, quindi otterrà una classificazione 18+ (PEGI 18). Sesso esplicito, anche disegnato, non è ammesso sul Play Store.
- **App Store:** imposta la classificazione 18+. Le linee guida Apple (1.1.4) vietano il materiale apertamente sessuale. Il gioco mostra il sesso solo per allusioni e cutscene implicite: mantieni questa linea se aggiungi contenuti.
- Il gioco ha già una schermata di verifica dell'età al primo avvio.
- Musica: servono i diritti d'uso dei brani dei Rosanf (vedi [MUSICA.md](MUSICA.md)).
