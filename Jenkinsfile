elifePipeline {
    node('containers-jenkins-plugin') {
        def commit
        def grobidTag
        def fullImageTag

        stage 'Checkout', {
            checkout scm
            commit = elifeGitRevision()
            grobidTag = sh(
                script: 'bash -c "source .env && echo \\$GROBID_TAG"',
                returnStdout: true
            ).trim()
            echo "GROBID_TAG: ${grobidTag}"
            assert grobidTag != ''
            fullImageTag = "${grobidTag}-${commit}"
            echo "Full image tag: ${fullImageTag}"
        }

        stage 'Build and run tests', {
            try {
                sh "IMAGE_TAG=${fullImageTag} REVISION=${commit} make ci-build-and-test"
            } finally {
                sh "IMAGE_TAG=${fullImageTag} REVISION=${commit} make ci-clean"
            }
        }

        stage 'Check GROBID label', {
            echo "Checking GROBID label..."
            def image = DockerImage.elifesciences(this, 'sciencebeam-trainer-grobid', fullImageTag)
            echo "Reading GROBID label of image: ${image.toString()}"
            def actualGrobidTag = sh(
                script: "./ci/docker-read-local-label.sh ${image.toString()} org.elifesciences.dependencies.grobid",
                returnStdout: true
            ).trim()
            echo "GROBID label: ${actualGrobidTag} (expected: ${grobidTag})"
            assert actualGrobidTag == grobidTag
        }

        elifeMainlineOnly {
            stage 'Merge to master', {
                elifeGitMoveToBranch commit, 'master'
            }

            stage 'Push unstable image', {
                def image = DockerImage.elifesciences(this, 'sciencebeam-trainer-grobid', fullImageTag)
                def unstable_image = image.addSuffixAndTag('_unstable', fullImageTag)
                unstable_image.tag(grobidTag).push()
                unstable_image.push()
            }
        }
    }
}
