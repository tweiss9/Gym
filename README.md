# Gym App

This cross-platform Flutter application is designed to create, manage, and track users' custom workout routines. The application allows users to create personalized workouts by specifying the workout name, adding exercises, and setting the number of sets and repetitions for each exercise. After each completed workout, the application saves the workout data so that users can review them later. All users are authenticated through Firebase, and their workout details are saved in a Firebase database.

## Download

Install the Android Version here

Install the IOS Version here.

## Clone the Repository

To clone the repository, follow these steps

1. Clone the repo

```
git clone https://github.com/tweiss9/Gym
```

2. Go into the repository

```
cd <YOUR_PROJECT_LOCATION>
```

3. Set Up Firebase account

```
npm install -g firebase-tools
firebase login
firebase init
```

4. Install dependencies

```
flutter pub get
```

5. Debug the app (must have an emulator to run)

```
flutter run
```

6. Build the app

For Android

```
flutter build apk
```

For IOS

```
flutter build ios
```

## Usage

1. Begin by logging in with your Google account or registering a new account.
2. Tap the "Create Workout" button to create a personalized exercise routine.
3. Select your created workout and hit "Start" to begin.
4. Add the first exercise to the workout.
5. Customize the routine by adding exercises. Customize sets, weights, and reps as necessary.
6. Check off completed sets as you advance through your workout.
7. Wrap up your session by hitting "Finish Workout."
8. You can create more workouts, or continue with previous workouts.
9. Access past workouts by navigating to the history tab.
