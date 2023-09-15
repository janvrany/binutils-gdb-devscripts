def targets = [ 'x86_64-w64-mingw32', 'x86_64-pc-linux-gnu' /*, 'riscv64-unknown-linux-gnu'*/ ]

GDB_REPO   = (env.GDB_REPO != null)   ? env.GDB_REPO   : 'https://github.com/janvrany/binutils-gdb.git'
GDB_BRANCH = (env.GDB_BRANCH != null) ? env.GDB_BRANCH : 'users/jv/vdb'

def build() {
    stage ( "Checkout") {
        checkout scm
        checkout([$class: 'GitSCM',
                  branches: [[name: "*/${GDB_BRANCH}"]],
                  userRemoteConfigs: [[url: GDB_REPO]],
                  extensions: [[$class: 'CloneOption', noTags: true, reference: '', shallow: true],
                               [$class: 'RelativeTargetDirectory', relativeTargetDir: 'src/binutils-gdb']]])
    }

    stage ( "Compile" ) {
        sh "bash -x release.sh"
    }
    stage ( "Archive artifacts" ) {
        archiveArtifacts "src/binutils-gdb/release/gdb_${target}*${env.BUILD_NUMBER}.zip"
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
