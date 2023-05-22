import Foundation

enum ChatStorageIdentifiers: String {
    case topicToInvitationPubKey = "com.walletconnect.chat.topicToInvitationPubKey"
    case messages = "com.walletconnect.chat.messages"
    case receivedInvites = "com.walletconnect.chat.receivedInvites"

    case thread = "com.walletconnect.chat.threads"
    case sentInvite = "com.walletconnect.chat.sentInvites"
    case inviteKey = "com.walletconnect.chat.inviteKeys"
    case receivedInviteStatus = "com.walletconnect.chat.receivedInviteStatuses"
}
