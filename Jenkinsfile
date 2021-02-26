// SPDX-FileCopyrightText: 2021 Michael Jansen <info@michael-jansen.biz>
// SPDX-License-Identifier: CC0-1.0

pipeline {

    agent {
        label "elixir"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: "10"))
    }

    stages {

        stage("Cache [DEV]") {
            when {
                branch "master"
            }
            environment {
                MIX_ENV = "dev"
            }
            steps {
                // Download the cache
                copyArtifacts(projectName: env.JOB_NAME, optional: true, fingerprintArtifacts: true)
            }
        }

        stage("Build [DEV]") {
            environment {
                MIX_ENV = "dev"
            }
            steps {
                // Install hex
                // Not yet https://github.com/elixir-lang/elixir/issues/6453
                // sh "mix local.hex --if-missing"
                sh "mix local.hex --force"
                sh "mix local.rebar --force"

                // Get and compile the dependencies
                sh "mix deps.get"
                sh "mix deps.compile"

                sh "mix compile"
            }
        }

        stage("Assets [PROD]" ) {
            steps {
                dir("apps/inventory_web/") {
                    sh "npm install --prefix ./assets"
                    sh "npm run deploy --prefix ./assets"
                    sh "mix phx.digest"
                }
            }
        }


        stage("Test [TEST]") {
            environment {
                MIX_ENV = "test"
            }
            steps {

                // Install hex
                sh "mix local.hex --if-missing"
                // Install rebar (doesn't have --if-missing)
                sh "mix local.rebar --force"

                // Get and compile the dependencies
                sh "mix deps.get"
                sh "mix deps.compile"

                sh "mix compile"
                sh "mix test --cover"
            }
            post {
                success {
                    // register the junit output
                    junit skipPublishingChecks: true,
                          testResults: "_build/test/lib/**/test-junit-report.xml"

                    // publish coverage
                    step([$class             : 'CoberturaPublisher',
                          autoUpdateHealth   : false,
                          autoUpdateStability: false,
                          coberturaReportFile: 'apps/**/coverage.xml',
                          failUnhealthy      : false,
                          failUnstable       : false,
                          maxNumberOfBuilds  : 0,
                          onlyStable         : false,
                          sourceEncoding     : 'ASCII',
                          zoomCoverageChart  : false])

                }
            }
        }

        stage("POST BUILD [DEV]") {
            environment {
                MIX_ENV = "dev"
            }
            stages {

                stage("documentation") {
                    steps {
                        sh "mix docs"
                    }
                    post {
                        success {
                            // publish html
                            publishHTML target: [
                                    allowMissing         : false,
                                    alwaysLinkToLastBuild: false,
                                    keepAll              : true,
                                    reportDir            : '_build/doc',
                                    reportFiles          : 'index.html',
                                    reportName           : 'API Documentation'
                            ]
                        }
                    }
                }

                stage("dialyzer" ) {
                    steps {
                        sh "mix dialyzer"
                    }
                    post {
                        success {
                            // Upload the PLT files as Jenkins artifacts
                            archiveArtifacts artifacts: '_build/dev/dialyxir*'
                        }
                    }
                }

                stage("credo") {
                    steps {
                        sh """
                        set -o errexit -o nounset
                        # https://hexdocs.pm/credo/exit_statuses.html
                        mix credo || (
                            rc=\$?

                            # Only fail on warnings
                            if (( \$rc & 0x10 )) ; then
                                echo "We have warnings"
                                exit 1;
                            fi
                        )
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            emailext (
                subject: "Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' ${currentBuild.currentResult}",
                body: """
                    <p>${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                    <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>
                    """,
                mimeType: "text/html",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']] )
        }
    }
}
