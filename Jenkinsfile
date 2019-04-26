elifePipeline {
    node('containers-jenkins-plugin') {
        def commit
        def grobidTag
        def fullImageTag

        stage 'Checkout', {
            checkout scm
            commit = elifeGitRevision()
            grobidTag = sh(
                script: 'bash -c "source .env && echo \$GROBID_TAG"',
                returnStdout: true
            ).trim()
            echo "GROBID_TAG: ${grobidTag}"
            assert grobidTag != ''
            fullImageTag = "${grobidTag}-${commit}"
            echo "Full image tag: ${fullImageTag}"
        }

        stage 'Build and run tests', {
            try {
                sh "make ci-build-and-test"
            } finally {
                sh "make ci-clean"
            }
        }

        stage 'Check GROBID label', {
            def image = DockerImage.elifesciences(this, 'sciencebeam-trainer-grobid', fullImageTag)
            def actualGrobidTag = sh(
                script: "docker-read-label ${image} org.elifesciences.dependencies.grobid",
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
                unstable_image.tag("${grobidTag}-latest").push()
                unstable_image.push()
            }
        }
    }
}
