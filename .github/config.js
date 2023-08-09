module.exports = {
  branchPrefix: 'test-renovate/',
  username: 'renovate-release',
  gitAuthor: 'Renovate Bot <bot@renovateapp.com>',
  platform: 'github',
  includeForks: true,
  dryRun: null,
  repositories: ['guerzon/vaultwarden'],
    extends: ['config:base'],
    allowPostUpgradeCommandTemplating: true,
    allowedPostUpgradeCommands: ['^.*'],
    regexManagers: [
        {
            fileMatch: ['(^|/)Chart\\.yaml$'],
            matchStrings: [
                '#\\s?renovate: image=(?<depName>.*?)\\s?appVersion:\\s?\\"?(?<currentValue>[\\w+\\.\\-]*)',
            ],
            datasourceTemplate: 'docker',
        },
    ],
    packageRules: [
        {
            matchManagers: ['helm-requirements', 'helm-values', 'regex'],
            postUpgradeTasks: {
                commands: [
                  `version=$(grep '^version:' {{{parentDir}}}/Chart.yaml | awk '{print $2}')
                  major=$(echo $version | cut -d. -f1)
                  minor=$(echo $version | cut -d. -f2)
                  patch=$(echo $version | cut -d. -f3)
                  minor=$(expr $minor + 1)
                  echo "Replacing $version with $major.$minor.$patch"
                  sed -i "s/^version:.*/version: $\{major\}.$\{minor\}.$\{patch\}/g" {{{parentDir}}}/Chart.yaml
                  cat {{{parentDir}}}/Chart.yaml
                  `,
                ],
            },
            fileFilters: ['**/Chart.yaml'],
            executionMode: 'branch',
        },
    ],
};
