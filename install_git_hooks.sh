# 1. Create the pre-push hook file
cat << 'EOF' > .git/hooks/pre-push
#!/bin/bash

echo "🚀 Running Zola build before push..."

# Run the Zola build command
# We use --force to ensure the docs directory is overwritten correctly
zola build --output-dir docs --force

# Check if the build succeeded
if [ $? -ne 0 ]; then
  echo "❌ Zola build failed. Push aborted."
  exit 1
fi

# Check if there are unstaged changes in the docs/ folder
if [ -n "$(git status --porcelain docs/)" ]; then
  echo "⚠️  The 'docs/' folder is out of sync with your changes."
  echo "Please stage and commit the updated build before pushing."
  exit 1
fi

echo "✅ Build looks good. Proceeding with push."
exit 0
EOF

# 2. Make the script executable
chmod +x .git/hooks/pre-push