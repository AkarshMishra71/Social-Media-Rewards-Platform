// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ERC20 Token Interface
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SocialMediaRewardsPlatform {

    // Struct to store course details
    struct Course {
        uint256 courseId;
        string courseName;
        address creator;
        uint256 rewardPerLesson;
        uint256 totalLessons;
        bool isActive;
    }

    // Struct to store lesson details
    struct Lesson {
        uint256 lessonId;
        uint256 courseId;
        string lessonName;
        uint256 rewardAmount;
        bool isCompleted;
    }

    // Struct for social media task completion
    struct SocialMediaTask {
        bool isCompleted;
        uint256 rewardAmount;
    }

    // Mapping to store courses, lessons, user progress, and rewards
    mapping(uint256 => Course) public courses; // courseId -> Course
    mapping(uint256 => mapping(uint256 => Lesson)) public lessons; // courseId -> lessonId -> Lesson
    mapping(address => uint256) public userRewards; // user address -> total rewards
    mapping(address => mapping(uint256 => bool)) public userCourses; // user address -> courseId -> enrolled status
    mapping(address => mapping(uint256 => SocialMediaTask)) public userSocialMediaTasks; // user address -> courseId -> task completion status

    // Admin address
    address public admin;

    // ERC20 Token used for rewards
    IERC20 public rewardToken;

    // Events
    event CourseCreated(uint256 indexed courseId, string courseName, address indexed creator, uint256 rewardPerLesson);
    event LessonCreated(uint256 indexed courseId, uint256 indexed lessonId, string lessonName, uint256 rewardAmount);
    event CourseCompleted(address indexed student, uint256 indexed courseId, uint256 totalReward);
    event LessonCompleted(address indexed student, uint256 indexed courseId, uint256 indexed lessonId, uint256 rewardAmount);
    event SocialMediaTaskCompleted(address indexed student, uint256 indexed courseId, uint256 rewardAmount);
    event RewardWithdrawn(address indexed student, uint256 amount);

    // Modifier to restrict actions to admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Constructor to initialize the contract with the reward token address
    constructor(address _rewardToken) {
        admin = msg.sender;
        rewardToken = IERC20(_rewardToken);
    }

    // Function to create a course (only admin)
    function createCourse(string memory _courseName, uint256 _rewardPerLesson, uint256 _totalLessons) external onlyAdmin {
        uint256 courseId = uint256(keccak256(abi.encodePacked(_courseName, block.timestamp, msg.sender)));
        
        courses[courseId] = Course({
            courseId: courseId,
            courseName: _courseName,
            creator: msg.sender,
            rewardPerLesson: _rewardPerLesson,
            totalLessons: _totalLessons,
            isActive: true
        });

        emit CourseCreated(courseId, _courseName, msg.sender, _rewardPerLesson);
    }

    // Function to create a lesson under a course (only admin)
    function createLesson(uint256 _courseId, string memory _lessonName, uint256 _rewardAmount) external onlyAdmin {
        require(courses[_courseId].isActive, "Course does not exist or is inactive");

        uint256 lessonId = uint256(keccak256(abi.encodePacked(_lessonName, block.timestamp)));
        lessons[_courseId][lessonId] = Lesson({
            lessonId: lessonId,
            courseId: _courseId,
            lessonName: _lessonName,
            rewardAmount: _rewardAmount,
            isCompleted: false
        });

        emit LessonCreated(_courseId, lessonId, _lessonName, _rewardAmount);
    }

    // Function for users to enroll in a course
    function enrollInCourse(uint256 _courseId) external {
        require(courses[_courseId].isActive, "Course does not exist or is inactive");
        userCourses[msg.sender][_courseId] = true;
    }

    // Function for users to complete a lesson and earn rewards
    function completeLesson(uint256 _courseId, uint256 _lessonId) external {
        require(userCourses[msg.sender][_courseId], "User is not enrolled in this course");

        Lesson storage lesson = lessons[_courseId][_lessonId];
        require(!lesson.isCompleted, "Lesson already completed");

        lesson.isCompleted = true;
        userRewards[msg.sender] += lesson.rewardAmount;

        emit LessonCompleted(msg.sender, _courseId, _lessonId, lesson.rewardAmount);
    }

    // Function for users to complete a social media task and earn reward
    function completeSocialMediaTask(uint256 _courseId) external {
        require(userCourses[msg.sender][_courseId], "User is not enrolled in this course");

        SocialMediaTask storage task = userSocialMediaTasks[msg.sender][_courseId];
        require(!task.isCompleted, "Social media task already completed");

        task.isCompleted = true;
        task.rewardAmount = 50;  // Example fixed reward for completing a social media task
        userRewards[msg.sender] += task.rewardAmount;

        emit SocialMediaTaskCompleted(msg.sender, _courseId, task.rewardAmount);
    }

    // Function for users to withdraw earned rewards (ERC20 tokens)
    function withdrawRewards(uint256 _amount) external {
        require(userRewards[msg.sender] >= _amount, "Insufficient reward balance");

        userRewards[msg.sender] -= _amount;
        require(rewardToken.transfer(msg.sender, _amount), "Transfer failed");

        emit RewardWithdrawn(msg.sender, _amount);
    }

    // Admin function to deactivate a course
    function deactivateCourse(uint256 _courseId) external onlyAdmin {
        courses[_courseId].isActive = false;
    }

    // Admin function to set a new reward token (if required)
    function setRewardToken(address _rewardToken) external onlyAdmin {
        rewardToken = IERC20(_rewardToken);
    }
}
