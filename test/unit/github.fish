## Unit tests for GitHub owner/repo URL parsing (same logic as plugin).

@test "https URL: owner and repo extracted" (
    echo "https://github.com/Owner/Repo.git" | string replace -r '^.*[:/]([^/]+)/([^/]+?)(\.git)?$' '$1\n$2' | string trim | string collect
) = "Owner
Repo"

@test "https URL without .git: owner and repo extracted" (
    echo "https://github.com/Owner/Repo" | string replace -r '^.*[:/]([^/]+)/([^/]+?)(\.git)?$' '$1\n$2' | string trim | string collect
) = "Owner
Repo"

@test "git SSH URL: owner and repo extracted" (
    echo "git@github.com:Owner/Repo.git" | string replace -r '^.*[:/]([^/]+)/([^/]+?)(\.git)?$' '$1\n$2' | string trim | string collect
) = "Owner
Repo"

@test "first part is owner" (
    set -l parts (echo "https://github.com/MyOrg/my-repo.git" | string replace -r '^.*[:/]([^/]+)/([^/]+?)(\.git)?$' '$1\n$2')
    string trim -- $parts[1]
) = "MyOrg"

@test "second part is repo" (
    set -l parts (echo "https://github.com/MyOrg/my-repo.git" | string replace -r '^.*[:/]([^/]+)/([^/]+?)(\.git)?$' '$1\n$2')
    string trim -- $parts[2]
) = "my-repo"
