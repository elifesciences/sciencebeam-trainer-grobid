elifePipeline {
    node('containers-jenkins-plugin') {
        def commit
        def allGrobidTags
        def grobidTag
        def fullImageTag

        stage 'Checkout', {
            checkout scm
            commit = elifeGitRevision()
            allGrobidTags = sh(
                script: 'bash -c "source .env && echo \\$ALL_GROBID_TAGS"',
                returnStdout: true
            ).trim().split(':')
            echo "allGrobidTags: ${allGrobidTags}"
            assert allGrobidTags != []
            grobidTag = allGrobidTags[0]
            assert allGrobidTags != ''
            fullImageTag = "${grobidTag}-${commit}"
            echo "Full image tag: ${fullImageTag}"
        }

        stage 'Build and run tests all grobid versions', {
            try {
                parallel(allGrobidTags.inject([:]) { m, _grobidTag ->
                    m["Build and run tests (${_grobidTag})"] = {
                        def _fullImageTag = "${grobidTag}-${commit}"
                        sh "IMAGE_TAG=${_fullImageTag} REVISION=${commit} make ci-build-and-test"

                        echo "Checking GROBID label..."
                        def image = DockerImage.elifesciences(this, 'sciencebeam-trainer-grobid', _fullImageTag)
                        echo "Reading GROBID label of image: ${image.toString()}"
                        def actualGrobidTag = sh(
                            script: "./ci/docker-read-local-label.sh ${image.toString()} org.elifesciences.dependencies.grobid",
                            returnStdout: true
                        ).trim()
                        echo "GROBID label: ${actualGrobidTag} (expected: ${_grobidTag})"
                        assert actualGrobidTag == _grobidTag
                    }
                    return m
                })
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
                unstable_image.tag(grobidTag).push()
                unstable_image.push()
            }
        }
    }
}
