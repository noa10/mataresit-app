#!/bin/bash

# Mataresit App - Build Optimization Script
# This script optimizes the build process for faster CI/CD execution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENABLE_CACHING=true
PARALLEL_BUILDS=true
OPTIMIZE_GRADLE=true
PRECOMPILE_FLUTTER=true
CLEAN_CACHE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --no-cache               Disable caching optimizations"
    echo "  --no-parallel            Disable parallel builds"
    echo "  --no-gradle-opt          Disable Gradle optimizations"
    echo "  --no-precompile          Disable Flutter precompilation"
    echo "  --clean-cache            Clean all caches before optimization"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                       # Apply all optimizations"
    echo "  $0 --clean-cache         # Clean caches first"
    echo "  $0 --no-parallel         # Disable parallel builds"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            ENABLE_CACHING=false
            shift
            ;;
        --no-parallel)
            PARALLEL_BUILDS=false
            shift
            ;;
        --no-gradle-opt)
            OPTIMIZE_GRADLE=false
            shift
            ;;
        --no-precompile)
            PRECOMPILE_FLUTTER=false
            shift
            ;;
        --clean-cache)
            CLEAN_CACHE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

print_status "🚀 Optimizing Mataresit App build process..."
print_status "Caching: $ENABLE_CACHING"
print_status "Parallel builds: $PARALLEL_BUILDS"
print_status "Gradle optimization: $OPTIMIZE_GRADLE"
print_status "Flutter precompilation: $PRECOMPILE_FLUTTER"
print_status "Clean cache: $CLEAN_CACHE"

# Clean caches if requested
if [ "$CLEAN_CACHE" = true ]; then
    print_status "Cleaning caches..."
    
    # Flutter cache
    if command -v flutter &> /dev/null; then
        flutter clean
        print_success "Flutter cache cleaned"
    fi
    
    # Gradle cache
    if [ -d "$HOME/.gradle/caches" ]; then
        rm -rf "$HOME/.gradle/caches"
        print_success "Gradle cache cleaned"
    fi
    
    # Pub cache
    if [ -d "$HOME/.pub-cache" ]; then
        flutter pub cache clean
        print_success "Pub cache cleaned"
    fi
fi

# Optimize Gradle configuration
if [ "$OPTIMIZE_GRADLE" = true ]; then
    print_status "Optimizing Gradle configuration..."
    
    GRADLE_PROPERTIES="android/gradle.properties"
    
    # Create optimized gradle.properties
    cat > "$GRADLE_PROPERTIES" << EOF
# Gradle optimization settings for Mataresit App

# Enable Gradle daemon for faster builds
org.gradle.daemon=true

# Enable parallel builds
org.gradle.parallel=true

# Configure JVM heap size
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g -XX:+HeapDumpOnOutOfMemoryError

# Enable configuration cache (Gradle 6.6+)
org.gradle.configuration-cache=true

# Enable build cache
org.gradle.caching=true

# Configure workers
org.gradle.workers.max=4

# Enable configure on demand
org.gradle.configureondemand=true

# Android specific optimizations
android.useAndroidX=true
android.enableJetifier=true

# Enable R8 full mode for better optimization
android.enableR8.fullMode=true

# Enable non-transitive R classes
android.nonTransitiveRClass=true

# Enable incremental annotation processing
kapt.incremental.apt=true

# Enable incremental compilation
kotlin.incremental=true

# Enable parallel compilation
kotlin.parallel.tasks.in.project=true

# Use Kotlin compiler daemon
kotlin.compiler.execution.strategy=daemon

# Enable build features only when needed
android.defaults.buildfeatures.buildconfig=false
android.defaults.buildfeatures.aidl=false
android.defaults.buildfeatures.renderscript=false
android.defaults.buildfeatures.resvalues=false
android.defaults.buildfeatures.shaders=false
EOF

    print_success "Gradle configuration optimized"
fi

# Set up Flutter caching
if [ "$ENABLE_CACHING" = true ]; then
    print_status "Setting up Flutter caching..."
    
    # Create cache directories
    mkdir -p .flutter-cache
    mkdir -p .pub-cache-local
    
    # Set up pub cache
    export PUB_CACHE="$(pwd)/.pub-cache-local"
    
    print_success "Flutter caching configured"
fi

# Precompile Flutter if requested
if [ "$PRECOMPILE_FLUTTER" = true ]; then
    print_status "Precompiling Flutter..."
    
    if command -v flutter &> /dev/null; then
        # Precache Flutter artifacts
        flutter precache --android
        
        # Get dependencies
        flutter pub get
        
        # Generate code if needed
        if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
            print_status "Running code generation..."
            flutter packages pub run build_runner build --delete-conflicting-outputs
        fi
        
        print_success "Flutter precompilation completed"
    else
        print_warning "Flutter not found, skipping precompilation"
    fi
fi

# Create build optimization script for CI
print_status "Creating CI optimization script..."

cat > "scripts/ci-optimize.sh" << 'EOF'
#!/bin/bash

# CI Build Optimization Script
# This script is called by GitHub Actions to optimize builds

set -e

echo "🔧 Applying CI build optimizations..."

# Set environment variables for optimization
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.workers.max=4"
export FLUTTER_BUILD_MODE="release"

# Configure Git for faster operations
git config --global advice.detachedHead false
git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 0

# Set up Flutter environment
export FLUTTER_ROOT="$RUNNER_TOOL_CACHE/flutter/stable"
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Optimize Flutter settings
flutter config --no-analytics
flutter config --no-cli-animations

echo "✅ CI optimizations applied"
EOF

chmod +x scripts/ci-optimize.sh
print_success "CI optimization script created"

# Create cache warming script
print_status "Creating cache warming script..."

cat > "scripts/warm-cache.sh" << 'EOF'
#!/bin/bash

# Cache Warming Script
# Pre-populates caches for faster subsequent builds

set -e

echo "🔥 Warming build caches..."

# Warm Flutter cache
if command -v flutter &> /dev/null; then
    echo "Warming Flutter cache..."
    flutter doctor
    flutter precache --android
    flutter pub get
    flutter analyze --no-fatal-infos || true
fi

# Warm Gradle cache
if [ -f "android/gradlew" ]; then
    echo "Warming Gradle cache..."
    cd android
    ./gradlew tasks --all > /dev/null 2>&1 || true
    ./gradlew dependencies > /dev/null 2>&1 || true
    cd ..
fi

echo "✅ Cache warming completed"
EOF

chmod +x scripts/warm-cache.sh
print_success "Cache warming script created"

# Create performance monitoring script
print_status "Creating performance monitoring script..."

cat > "scripts/monitor-performance.sh" << 'EOF'
#!/bin/bash

# Performance Monitoring Script
# Monitors build performance and generates reports

set -e

BUILD_START_TIME=$(date +%s)
BUILD_LOG="build_performance.log"

echo "📊 Monitoring build performance..."
echo "Build started at: $(date)" > "$BUILD_LOG"

# Function to log performance metrics
log_metric() {
    local metric_name="$1"
    local metric_value="$2"
    echo "$metric_name: $metric_value" >> "$BUILD_LOG"
}

# Monitor system resources
if command -v free &> /dev/null; then
    MEMORY_USAGE=$(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')
    log_metric "Memory Usage" "$MEMORY_USAGE"
fi

if command -v df &> /dev/null; then
    DISK_USAGE=$(df -h . | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')
    log_metric "Disk Usage" "$DISK_USAGE"
fi

# Monitor build times
monitor_build_step() {
    local step_name="$1"
    local step_start=$(date +%s)
    
    echo "Starting: $step_name"
    shift
    
    # Execute the command
    "$@"
    
    local step_end=$(date +%s)
    local step_duration=$((step_end - step_start))
    
    log_metric "$step_name Duration" "${step_duration}s"
    echo "Completed: $step_name (${step_duration}s)"
}

# Export the function for use in other scripts
export -f monitor_build_step
export -f log_metric
export BUILD_LOG

echo "✅ Performance monitoring initialized"
echo "Use 'monitor_build_step \"Step Name\" command args' to monitor build steps"
EOF

chmod +x scripts/monitor-performance.sh
print_success "Performance monitoring script created"

# Create build matrix optimization
print_status "Creating build matrix optimization..."

cat > ".github/config/build-matrix.yml" << 'EOF'
# Build Matrix Optimization Configuration
# Defines optimized build strategies for different scenarios

# Default build configuration
default:
  flutter_version: "3.24.5"
  java_version: "17"
  gradle_version: "8.5"
  cache_enabled: true
  parallel_builds: true

# Build matrices for different scenarios
matrices:
  # Fast feedback for PRs
  pr_check:
    strategy:
      matrix:
        build_type: [debug]
        test_type: [unit, widget]
    optimization:
      skip_integration_tests: true
      use_cached_dependencies: true
      parallel_test_execution: true
      
  # Full build for releases
  release:
    strategy:
      matrix:
        build_type: [release]
        output_format: [apk, appbundle]
        architecture: [arm64-v8a, armeabi-v7a, x86_64]
    optimization:
      enable_r8_full_mode: true
      enable_proguard: true
      split_per_abi: true
      
  # Nightly builds
  nightly:
    strategy:
      matrix:
        build_type: [debug, profile, release]
        test_type: [unit, widget, integration]
    optimization:
      comprehensive_testing: true
      performance_profiling: true
      security_scanning: true

# Cache configuration
cache:
  # Flutter cache
  flutter:
    key: "flutter-${{ runner.os }}-${{ env.FLUTTER_VERSION }}-${{ hashFiles('**/pubspec.lock') }}"
    paths:
      - ~/.pub-cache
      - ${{ runner.tool_cache }}/flutter
      
  # Gradle cache
  gradle:
    key: "gradle-${{ runner.os }}-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}"
    paths:
      - ~/.gradle/caches
      - ~/.gradle/wrapper
      
  # Android SDK cache
  android_sdk:
    key: "android-sdk-${{ runner.os }}-${{ env.ANDROID_SDK_VERSION }}"
    paths:
      - ${{ env.ANDROID_HOME }}

# Performance optimizations
performance:
  # Gradle optimizations
  gradle:
    daemon: true
    parallel: true
    configure_on_demand: true
    max_workers: 4
    jvm_args: "-Xmx4g -XX:MaxMetaspaceSize=1g"
    
  # Flutter optimizations
  flutter:
    no_analytics: true
    no_cli_animations: true
    precache_artifacts: true
    
  # System optimizations
  system:
    git_config:
      - "advice.detachedHead false"
      - "core.preloadindex true"
      - "core.fscache true"
      - "gc.auto 0"
EOF

print_success "Build matrix optimization created"

# Summary
echo ""
print_success "🎉 Build optimization completed!"
echo ""
echo "📋 Optimizations Applied:"
if [ "$OPTIMIZE_GRADLE" = true ]; then
    echo "  ✅ Gradle configuration optimized"
fi
if [ "$ENABLE_CACHING" = true ]; then
    echo "  ✅ Caching strategies configured"
fi
if [ "$PRECOMPILE_FLUTTER" = true ]; then
    echo "  ✅ Flutter precompilation completed"
fi
echo "  ✅ CI optimization scripts created"
echo "  ✅ Performance monitoring configured"
echo "  ✅ Build matrix optimization defined"
echo ""
echo "📁 Created Files:"
echo "  - scripts/ci-optimize.sh"
echo "  - scripts/warm-cache.sh"
echo "  - scripts/monitor-performance.sh"
echo "  - .github/config/build-matrix.yml"
if [ "$OPTIMIZE_GRADLE" = true ]; then
    echo "  - android/gradle.properties (updated)"
fi
echo ""
echo "🚀 Next Steps:"
echo "  1. Commit the optimization files"
echo "  2. Test the optimizations locally"
echo "  3. Monitor CI/CD performance improvements"
echo "  4. Adjust settings based on build metrics"
