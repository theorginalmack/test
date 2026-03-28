terraform {
    cloud {
        organization = "Macksbusiness"

        workspaces {
            name = "test"
            project = "testingtesting"
        }
    }
}
