import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../features/privacy/domain/purge_mode.dart';

const String kGenericOperationFailed =
    'Something went wrong. Please try again.';

const String kNetworkError =
    'Network error. Check your connection and try again.';

const String kTemporaryServiceError =
    'The service is temporarily unavailable. Please try again.';

const String kDeviceStorageError =
    'Not enough device storage to complete this operation.';

const String kDeviceOperationError =
    "Couldn't complete this operation on this device.";

const String kPermissionError =
    "You don't have permission to complete this action.";

const String kAuthenticationError =
    'Could not confirm your sign-in details. Please try again.';

const String kReauthenticationRequired =
    'Please confirm your password again, then retry.';

/// Safe human copy for unexpected failures. Never returns [error] text.
String userFacingErrorMessage(Object error) {
  if (error is PurgeException) {
    switch (error.code) {
      case PurgeFailureCode.recentAuthRequired:
        return kReauthenticationRequired;
      case PurgeFailureCode.unauthenticated:
        return 'You need to be signed in.';
      case PurgeFailureCode.purgeRetryRequired:
        return 'Deletion did not finish. Please try again.';
      case PurgeFailureCode.purgeFailed:
      case PurgeFailureCode.unknown:
        return 'Deletion failed. Your account was not removed. Please try again.';
    }
  }

  if (error is FileSystemException) {
    return isInsufficientStorage(error)
        ? kDeviceStorageError
        : kDeviceOperationError;
  }

  if (error is PathAccessException || error is PathExistsException) {
    return kDeviceOperationError;
  }

  if (error is SocketException || error is TimeoutException) {
    return kNetworkError;
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'network-request-failed':
        return kNetworkError;
      case 'requires-recent-login':
        return kReauthenticationRequired;
      case 'too-many-requests':
        return kTemporaryServiceError;
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      case 'user-mismatch':
        return kAuthenticationError;
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is currently unavailable.';
      default:
        return kAuthenticationError;
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'aborted':
        return kTemporaryServiceError;
      case 'permission-denied':
        return kPermissionError;
      case 'unauthenticated':
        return kAuthenticationError;
      default:
        return kGenericOperationFailed;
    }
  }

  if (error is PlatformException) {
    final String code = error.code.toLowerCase();
    if (code.contains('network')) return kNetworkError;
    if (_looksLikeInsufficientStorage(code) ||
        _looksLikeInsufficientStorage(error.message)) {
      return kDeviceStorageError;
    }
    return kGenericOperationFailed;
  }

  if (error is ArgumentError) {
    return 'Check the values you entered and try again.';
  }

  return kGenericOperationFailed;
}

bool isInsufficientStorage(FileSystemException error) {
  final int? code = error.osError?.errorCode;
  if (code == 28) return true;
  return _looksLikeInsufficientStorage(error.osError?.message) ||
      _looksLikeInsufficientStorage(error.message);
}

bool _looksLikeInsufficientStorage(String? text) {
  if (text == null) return false;
  final String lower = text.toLowerCase();
  return lower.contains('no space') ||
      lower.contains('enospc') ||
      lower.contains('not enough space') ||
      lower.contains('not enough storage');
}
