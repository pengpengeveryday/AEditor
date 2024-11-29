import 'user.dart';

class UserRepository {
  // 单例模式
  static final UserRepository _instance = UserRepository._internal();
  
  factory UserRepository() {
    return _instance;
  }

  UserRepository._internal();

  // 模拟获取用户信息
  Future<User> getUser(String userId) async {
    // 这里模拟从API获取数据
    await Future.delayed(const Duration(seconds: 1));
    
    return User(
      id: userId,
      name: 'Test User',
      email: 'test@example.com',
    );
  }

  // 模拟更新用户信息
  Future<bool> updateUser(User user) async {
    // 这里模拟向API提交数据
    await Future.delayed(const Duration(seconds: 1));
    
    return true;
  }
} 