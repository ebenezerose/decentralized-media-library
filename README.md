# Decentralized Media Library Smart Contract

## Overview
The **Decentralized Media Library** is a smart contract designed to manage a decentralized library of media files. This contract allows users to:
- Create, edit, transfer, and delete media entries.
- Grant and revoke access rights to other users.
- Enforce ownership and access permissions.

The contract ensures data integrity and security using error codes and permissions.

---

## Features
- **Media Management**: Add, edit, delete, and transfer ownership of media entries.
- **Access Control**: Grant or revoke read access for specific users.
- **Validation**: Strict input validation for media properties such as size, name, category, and tags.
- **Permissions**: Only authorized users can modify or transfer their owned media.

---

## Error Codes
| Error Code | Description                              |
|------------|------------------------------------------|
| `u301`     | Media entry not found.                  |
| `u302`     | Attempt to create a duplicate media.    |
| `u303`     | Invalid media name.                     |
| `u304`     | Invalid media size.                     |
| `u305`     | Unauthorized action.                    |
| `u306`     | Invalid media category.                 |
| `u307`     | Restricted action.                      |
| `u308`     | Access denied.                          |
| `u309`     | Invalid access grant attempt.           |
| `u310`     | Invalid principal address.              |

---

## Data Structures
### Global Counters
- **`media-count`**: Tracks the total number of media entries.

### Mappings
- **`media-entries`**:
  - Stores details of each media file.
  - Keys: Media ID.
  - Values:
    - `name`: Name of the media.
    - `owner`: Owner's principal address.
    - `data-size`: Size of the media file.
    - `timestamp`: Block height when added.
    - `category`: Category of the media.
    - `overview`: Brief description of the media.
    - `tags-list`: Associated tags.

- **`access-rights`**:
  - Manages access control for users.
  - Keys: Combination of Media ID and user principal.
  - Values:
    - `can-access`: Boolean indicating access permission.
    - `granted-by`: Principal who granted the access.
    - `granted-at`: Block height when access was granted.

---

## Public Functions

### Media Management
1. **`create-media`**:
   - **Description**: Creates a new media entry.
   - **Inputs**: `name`, `size`, `category`, `overview`, `tags`.
   - **Outputs**: Media ID.

2. **`edit-media`**:
   - **Description**: Edits an existing media entry.
   - **Inputs**: Media ID, updated media details.
   - **Outputs**: Success status.

3. **`delete-media`**:
   - **Description**: Deletes a media entry.
   - **Inputs**: Media ID.
   - **Outputs**: Success status.

4. **`transfer-ownership`**:
   - **Description**: Transfers ownership of a media entry.
   - **Inputs**: Media ID, new owner's principal.
   - **Outputs**: Success status.

### Access Management
1. **`grant-read-access`**:
   - **Description**: Grants read access to a specific user.
   - **Inputs**: Media ID, user's principal.
   - **Outputs**: Success status.

2. **`revoke-read-access`**:
   - **Description**: Revokes read access from a specific user.
   - **Inputs**: Media ID, user's principal.
   - **Outputs**: Success status.

3. **`check-access`** (Read-Only):
   - **Description**: Checks if a user has read access to a media entry.
   - **Inputs**: Media ID, user's principal.
   - **Outputs**: Boolean access status.

---

## Internal Utility Functions
1. **`is-media-present?`**:
   - Checks if a media entry exists.
2. **`is-authorized-owner?`**:
   - Verifies if a user is the owner of a media entry.
3. **`has-read-access?`**:
   - Determines if a user has read access to a media entry.
4. **`validate-tag-set`**:
   - Validates the format and length of tags.

---

## Contract Deployment
1. Deploy the contract using Clarity-compatible tools (e.g., Clarinet).
2. Set `LIBRARY_ADMIN` to the principal deploying the contract.

---

## Example Usage
### Create Media
```clarity
(create-media "Sample Media" u1024 "Entertainment" "A fun video." ['fun', 'video'])
```

### Grant Access
```clarity
(grant-read-access u1 'ST3J2GVMMM2R07ZFBJDWTYEYAR8FZH5WKDTFJ9AHA)
```

### Check Access
```clarity
(check-access u1 'ST3J2GVMMM2R07ZFBJDWTYEYAR8FZH5WKDTFJ9AHA)
```

---

## Security Considerations
- Only the owner can edit, transfer, or delete media entries.
- Access rights are controlled through strict validation.
- Unauthorized actions are rejected with error codes.

---

## License
This contract is released under the MIT License.
```