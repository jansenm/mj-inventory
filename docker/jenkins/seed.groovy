multibranchPipelineJob('build') {
    displayName("Build the project")
    description("Build the project")
    branchSources {
        git {
            id('project') // IMPORTANT: use a constant and unique identifier
            remote('git@tuxedo-xps')
            includes('*')
            excludes('archive/*')

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