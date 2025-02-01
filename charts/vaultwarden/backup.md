# Backup

This backup solution is designed for a SQLite local database and single-instance VaultWarden deployment. It can also be used for attachments, while persistent PostgreSQL/MySQL backups should be handled separately.

The backup utilizes the [vaultwarden-backup](https://github.com/ttionya/vaultwarden-backup) solution. Each scheduled backup creates an additional sidecar vaultwarden-backup container where the data folder is shared between the VaultWarden container and the backup sidecar container.

## VaultWarden Settings

For the backup to access the data, VaultWarden must run with an appropriate security context, matching the backup container. For example:

```yaml
podSecurityContext:
  ## @param runAsGroup group ID for VaultWarden and backup run with
  ## Same as default user for vaultwarden-backup
  runAsUser: 1100
  runAsGroup: 1100
  fsGroup: 1100
```

## Parameters


| Name                                | Description                                                                                                                                                                         | Value                                           |
|-------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------|
| `backup.enabled`                    | Enable the backup                                                                                                                                                                   | true/false                                      |
| `backup.image`                      | Docker image, see https://hub.docker.com/r/ttionya/vaultwarden-backup                                                                                                               | <docker image>                                  |
| `backup.rcloneConfig`               | [rClone config](https://github.com/ttionya/vaultwarden-backup?tab=readme-ov-file#configure-rclone-%EF%B8%8F-must-read-%EF%B8%8F). Recommended to keep it secure, sops, helm secrets | <config>                                        |
| `backup.remoteName`                 | Backup remote name, see [RCLONE_REMOTE_NAME](https://github.com/ttionya/vaultwarden-backup?tab=readme-ov-file#rclone_remote_name)                                                   |                                                 |
| `backup.globalFlags`                | rClone global flags [RCLONE_GLOBAL_FLAG](https://github.com/ttionya/vaultwarden-backup?tab=readme-ov-file#rclone_global_flag)                                                       |                                                 |
| `backup.zipPassword`                | Password to encrypt backup archive with, see [ZIP_PASSWORD](https://github.com/ttionya/vaultwarden-backup?tab=readme-ov-file#zip_password)                                          |                                                 |
| `backup.healthcheckPingKey`         | See [Ping, Healthchecks.io](https://github.com/ttionya/vaultwarden-backup?tab=readme-ov-file#ping)                                                                                  |                                                 |
| `backup.timezone`                   | Backup timezone, see [TIMEZONE](https://github.com/ttionya/vaultwarden-backup?tab=readme-ov-file#timezone).                                                                         | UTC                                             |
| `backup.smtp...`                    | SMTP parameters, [Mail](https://github.com/ttionya/vaultwarden-backup?tab=readme-ov-file#mail)                                                                                      |                                                 |
| `backup.backups`                    | Array of backups, each of it's own schedule                                                                                                                                         |                                                 |
| `backup.backups[].name`             | Backup name, container to be named after it                                                                                                                                         | "hourly", "weekly" etc                          |
| `backup.backups[].schedule`         | Cron job syntax schedule                                                                                                                                                            | "5 * * * *"                                     |       
| `backup.backups[].keepDays`         | Backup to be delete after these N days. 0 - keep forever                                                                                                                            | 7, 0 ...                                        |
| `backup.backups[].fileDateSuffix`   | Suffix for the each archive file                                                                                                                                                    | "-%H-%M-%S"                                     |
| `backup.backups[].healthCheckPing`  | healthchecks.io ping url, see [Ping](). Such as `https://hc-ping.com/{ping_key}/vaultwarden-<name>` Set it on most-frequent backup                                                  | https://hc-ping.com/{ping_key}/vaultwarden-main |
|                                     |                                                                                                                                                                                     |                                                 |
|                                     |                                                                                                                                                                                     |                                                 |

### Example
```yaml
podSecurityContext:
  ## @param runAsGroup group ID for VaultWarden and backup run with
  ## Same as default user for vaultwarden-backup
  runAsUser: 1100
  runAsGroup: 1100
  fsGroup: 1100

backup:
  enabled: true
  backups:
    - name: hourly
      remoteDir: "/vaultWarden-main/hourly/"
      # Every hour at 5 mins
      cron: "5 * * * *"
      keepDays: 7
      fileDateSuffix: "-%H-%M-%S"
      healthCheckPing: "https://hc-ping.com/<my-key>/vaultwarden-main"

    - name: daily
      remoteDir: "/vaultWarden-main/daily/"
      # every day at 03:23
      cron: "23 3 * * *"
      keepDays: 60
      fileDateSuffix: "-%H-%M-%S"

    - name: monthly
      remoteDir: "/vaultWarden-main/monthly/"
      # every 20th day at 03:47
      cron: "47 3 20 * *"
      # Keep forever
      keepDays: 0
      fileDateSuffix: "-%H-%M-%S"
```

## Restore

If the deployment is lost, including PVs, it can be restored from the backup:

1. Download the backup archive from remote storage.
2. Have the `zipPassword` ready for unzipping the archive.
3. Run the restore script (requires functional kubectl):

`./restore.sh --archive <archive-file> --release <helm-release> --storage-class <Storage class>`

Example: 

   `./restore.sh --archive /tmp/backup.20221103-19-05-01.zip --release vaultwarden --storage-class "local-path"`

Kubernetes Namespace and context can be set with kubectl beforehand or passed as arguments.

The script will create a PV and PVC in the target cluster and namespace. When the VaultWarden helm chart is deployed, it will use this PV and PVC.

Use kubectl to check if another PVC is created in case of a mismatch. Adjust script parameters accordingly.  




