multibranchPipelineJob('build') {
    displayName("Build the project")
    description("Build the project")
    branchSources {
        git {
            id('project') // IMPORTANT: use a constant and unique identifier
            remote('git@tuxedo-xps:elixir/mj-inventory')
            includes('*')
            excludes('archive/*')
            credentialsId('ssh-key-tuxedo-xps-git')

        }
    }
    orphanedItemStrategy {
        discardOldItems {
            numToKeep(20)
        }
    }

    triggers {
        periodicFolderTrigger {
            interval("10m")
        }
    }
}