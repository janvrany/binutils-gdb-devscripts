def targets = [ 'x86_64-pc-linux-gnu' /*, 'x86_64-w64-mingw32' */ /*, 'riscv64-unknown-linux-gnu'*/ ]



properties([
    parameters([
        string(name: 'GDB_REPO', defaultValue: 'git://sourceware.org/git/binutils-gdb.git', description: 'Repository to clone from'), 
        string(name: 'GDB_COMMIT', defaultValue: 'master', description: 'Branch to clone'), 
        credentials(name: 'GDB_REPO_CREDENTIALS', defaultValue: '', description: 'Credentials to use when cloning the repo (specified by GDB_REPO param)', required: false)
    ])
])

def build() {
    stage ( "Checkout") {
        //checkout scm

        echo "GDB_REPO:             ${params.GDB_REPO}"
        echo "GDB_COMMIT:           ${params.GDB_COMMIT}"
        echo "GDB_REPO_CREDENTIALS: ${params.GDB_REPO_CREDENTIALS}"

        checkout([$class: 'GitSCM',
                  branches: [[name: "*/master"]],
                  userRemoteConfigs: [[url: "https://github.com/janvrany/binutils-gdb-devscripts"]],
                  extensions: [[$class: 'CloneOption', noTags: true, reference: '', shallow: true]]])

        checkout([$class: 'GitSCM',
                  branches: [[name: "${params.GDB_COMMIT}"]],
                  userRemoteConfigs: [[url: "${params.GDB_REPO}",credentialsId: "${params.GDB_REPO_CREDENTIALS}"]],
                  extensions: [[$class: 'CloneOption', noTags: true, reference: '', shallow: true],
                               [$class: 'RelativeTargetDirectory', relativeTargetDir: 'src/binutils-gdb']]])

        currentBuild.displayName = "${currentBuild.displayName} ${params.GDB_COMMIT}"
    }

    stage ( "Compile & Test" ) {
        try {
            sh "bash -x test.sh"
        } finally {
            junit "results/gdb.xml"
            archiveArtifacts "results/gdb.log"
        }
    }

    stage ( "Cleanup ") {
        cleanWs()
    }
}

def branches = [:]
for (each in targets) {
    def target = each
    branches[target] = {
        withEnv( [ "target=$target"] ) {
            node ( "${env.target}" ) {
                ws ("${workspace}/${env.target}" ) {
                    build()
                }
            }
        }
    }
}
parallel branches
