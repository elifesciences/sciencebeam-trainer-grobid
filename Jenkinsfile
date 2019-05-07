elifePipeline {
    node('containers-jenkins-plugin') {
        def commit
        def allGrobidTags

        stage 'Checkout', {
            checkout scm
            commit = elifeGitRevision()
            allGrobidTags = sh(
                script: 'bash -c "source .env && echo \\$ALL_GROBID_TAGS"',
                returnStdout: true
            ).trim().split(',')
            echo "allGrobidTags: ${allGrobidTags}"
            assert allGrobidTags != []
        }

        stage 'Build', {
            try {
                parallel(allGrobidTags.inject([:]) { m, grobidTag ->
                    m["Build (${grobidTag})"] = {
                        def fullImageTag = "${grobidTag}-${commit}"
                        sh "GROBID_TAG=${grobidTag} IMAGE_TAG=${fullImageTag} REVISION=${commit} make ci-build"

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
                    return m
                })
            } finally {
                sh "make ci-clean"
            }
        }

        stage 'Project Tests', {
            try {
                def grobidTag = allGrobidTags.last()
                def fullImageTag = "${grobidTag}-${commit}"
                sh "GROBID_TAG=${grobidTag} IMAGE_TAG=${fullImageTag} REVISION=${commit} make ci-test-only"
            } finally {
                sh "make ci-clean"
            }
        }

        elifeMainlineOnly {
            stage 'Merge to master', {
                elifeGitMoveToBranch commit, 'master'
            }

            stage 'Push unstable image', {
                parallel(allGrobidTags.inject([:]) { m, grobidTag ->
                    m["Push unstable image (${grobidTag})"] = {
                        def fullImageTag = "${grobidTag}-${commit}"
                        def image = DockerImage.elifesciences(this, 'sciencebeam-trainer-grobid', fullImageTag)
                        def unstable_image = image.addSuffixAndTag('_unstable', fullImageTag)
                        unstable_image.tag(grobidTag).push()
                        unstable_image.push()
                    }
                    return m
                })
            }
        }
    }
}
