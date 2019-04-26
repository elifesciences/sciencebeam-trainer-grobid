elifePipeline {
    node('containers-jenkins-plugin') {
        def commit
        def grobidTag
        def fullImageTag

        stage 'Checkout', {
            checkout scm
            commit = elifeGitRevision()
            grobidTag = sh('source .env && echo $GROBID_TAG', returnStdout: true)
            echo "GROBID_TAG: ${grobidTag}"
            fullImageTag = sh(
                script: "docker-compose config | grep -P -o '(?<=\\simage: elifesciences/sciencebeam-trainer-grobid-builder:)\\S+'",
                returnStdout: true
            ).trim()
            echo "Full image tag: ${fullImageTag}"
        }

        stage 'Build and run tests', {
            try {
                sh "make ci-build-and-test"
            } finally {
                sh "make ci-clean"
            }
        }

        elifeMainlineOnly {
            stage 'Merge to master', {
                elifeGitMoveToBranch commit, 'master'
            }

            stage 'Push unstable image', {
                def image = DockerImage.elifesciences(this, 'sciencebeam-trainer-grobid', fullImageTag)
                def unstable_image = image.addSuffixAndTag('_unstable', fullImageTag)
                unstable_image.tag("${grobidTag}-latest").push()
                unstable_image.push()
            }
        }
    }
}
