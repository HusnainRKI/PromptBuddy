const Category = require('../models/Category');
const Prompt = require('../models/Prompt');
const { testConnection } = require('../config/database');

async function seedDatabase() {
  console.log('🌱 Starting database seeding...');
  
  try {
    // Test database connection
    const dbConnected = await testConnection();
    if (!dbConnected) {
      throw new Error('Database connection failed');
    }

    // Create sample categories
    console.log('📁 Creating sample categories...');
    
    const photoEditingCategory = await Category.create({
      name: 'Photo Editing',
      icon: 'camera',
      color: 0xFF9C27B0 // Purple
    });
    
    const codeCategory = await Category.create({
      name: 'Code',
      icon: 'code',
      color: 0xFF2196F3 // Blue
    });
    
    const socialMediaCategory = await Category.create({
      name: 'Social Media',
      icon: 'share',
      color: 0xFF4CAF50 // Green
    });

    console.log('✅ Categories created successfully');

    // Create sample prompts
    console.log('📝 Creating sample prompts...');

    // Photo Editing prompts
    await Prompt.create({
      title: 'Professional Photo Enhancement',
      body: 'Enhance this {{image_type}} photo with the following adjustments: {{adjustments}}. Make sure to maintain natural colors and improve the overall composition. Focus on {{main_subject}} and apply {{style}} processing.',
      categoryId: photoEditingCategory.id,
      tags: ['enhancement', 'professional', 'editing']
    });

    await Prompt.create({
      title: 'Portrait Retouching',
      body: 'Retouch this portrait photo of {{subject}}. Apply skin smoothing with {{intensity}} intensity, enhance eye brightness, and adjust the lighting to create a {{mood}} atmosphere. Remove any distracting elements in the {{background_area}}.',
      categoryId: photoEditingCategory.id,
      tags: ['portrait', 'retouching', 'beauty']
    });

    await Prompt.create({
      title: 'Landscape Color Grading',
      body: 'Apply color grading to this landscape photo taken during {{time_of_day}}. Enhance the {{dominant_colors}} tones, increase contrast in the {{focal_area}}, and create a {{atmosphere}} mood. Adjust shadows and highlights for optimal dynamic range.',
      categoryId: photoEditingCategory.id,
      tags: ['landscape', 'color-grading', 'nature']
    });

    // Code prompts
    await Prompt.create({
      title: 'Function Documentation',
      body: 'Create comprehensive documentation for this {{language}} function:\n\n```{{language}}\n{{code}}\n```\n\nInclude:\n- Purpose and functionality\n- Parameters with types and descriptions\n- Return value explanation\n- Usage examples\n- Edge cases and error handling',
      categoryId: codeCategory.id,
      tags: ['documentation', 'function', 'api']
    });

    await Prompt.create({
      title: 'Code Review Request',
      body: 'Please review this {{language}} code for {{feature_name}}:\n\n```{{language}}\n{{code}}\n```\n\nFocus on:\n- Code quality and best practices\n- Performance optimization\n- Security considerations\n- Maintainability and readability\n- Testing suggestions',
      categoryId: codeCategory.id,
      tags: ['code-review', 'quality', 'optimization']
    });

    await Prompt.create({
      title: 'Bug Fix Analysis',
      body: 'Help me debug this {{language}} issue:\n\n**Problem:** {{problem_description}}\n\n**Code:**\n```{{language}}\n{{problematic_code}}\n```\n\n**Error Message:** {{error_message}}\n\n**Expected Behavior:** {{expected_behavior}}\n\nPlease provide a solution with explanation.',
      categoryId: codeCategory.id,
      tags: ['debugging', 'troubleshooting', 'fix']
    });

    await Prompt.create({
      title: 'Algorithm Implementation',
      body: 'Implement a {{algorithm_type}} algorithm in {{language}} that:\n\n**Requirements:**\n- {{requirement_1}}\n- {{requirement_2}}\n- {{requirement_3}}\n\n**Constraints:**\n- Time complexity: {{time_complexity}}\n- Space complexity: {{space_complexity}}\n\nProvide the implementation with comments and test cases.',
      categoryId: codeCategory.id,
      tags: ['algorithm', 'implementation', 'performance']
    });

    // Social Media prompts
    await Prompt.create({
      title: 'Instagram Post Caption',
      body: 'Create an engaging Instagram caption for a {{post_type}} post about {{topic}}. \n\n**Tone:** {{tone}}\n**Target Audience:** {{audience}}\n**Call to Action:** {{cta}}\n\nInclude relevant hashtags and emojis. Keep it authentic and engaging while encouraging {{engagement_goal}}.',
      categoryId: socialMediaCategory.id,
      tags: ['instagram', 'caption', 'engagement']
    });

    await Prompt.create({
      title: 'Twitter Thread',
      body: 'Create a Twitter thread about {{topic}} with {{tweet_count}} tweets.\n\n**Key Points to Cover:**\n- {{point_1}}\n- {{point_2}}\n- {{point_3}}\n\n**Tone:** {{tone}}\n**Target:** {{target_audience}}\n\nMake each tweet engaging and ensure smooth flow between tweets. Include relevant hashtags.',
      categoryId: socialMediaCategory.id,
      tags: ['twitter', 'thread', 'content']
    });

    await Prompt.create({
      title: 'LinkedIn Professional Post',
      body: 'Write a professional LinkedIn post about {{topic}} that will resonate with {{target_profession}} professionals.\n\n**Key Message:** {{main_message}}\n**Personal Experience:** {{experience}}\n**Call to Action:** {{cta}}\n\nMake it thought-provoking and encourage professional discussion. Include relevant industry hashtags.',
      categoryId: socialMediaCategory.id,
      tags: ['linkedin', 'professional', 'networking']
    });

    await Prompt.create({
      title: 'YouTube Video Description',
      body: 'Create a compelling YouTube video description for "{{video_title}}".\n\n**Video Content:** {{content_summary}}\n**Duration:** {{duration}}\n**Target Keywords:** {{keywords}}\n\n**Include:**\n- Engaging hook\n- Detailed description\n- Timestamps for key sections\n- Links to {{related_resources}}\n- Subscribe call-to-action\n- Relevant tags',
      categoryId: socialMediaCategory.id,
      tags: ['youtube', 'description', 'seo']
    });

    await Prompt.create({
      title: 'Social Media Content Calendar',
      body: 'Create a {{duration}} social media content calendar for {{platform}} focusing on {{niche}}.\n\n**Brand Voice:** {{brand_voice}}\n**Posting Frequency:** {{frequency}}\n**Goals:** {{goals}}\n\n**Content Types to Include:**\n- {{content_type_1}}\n- {{content_type_2}}\n- {{content_type_3}}\n\nProvide specific post ideas with optimal posting times and engagement strategies.',
      categoryId: socialMediaCategory.id,
      tags: ['planning', 'calendar', 'strategy']
    });

    console.log('✅ Sample prompts created successfully');

    // Display summary
    const totalCategories = await require('../config/database').executeQuery(
      'SELECT COUNT(*) as count FROM categories'
    );
    const totalPrompts = await require('../config/database').executeQuery(
      'SELECT COUNT(*) as count FROM prompts'
    );

    console.log('\n📊 Seeding Summary:');
    console.log(`📁 Categories: ${totalCategories[0].count}`);
    console.log(`📝 Prompts: ${totalPrompts[0].count}`);
    console.log('🎉 Database seeding completed successfully!\n');

  } catch (error) {
    console.error('❌ Seeding failed:', error);
    throw error;
  }
}

// Run seeding if called directly
if (require.main === module) {
  seedDatabase()
    .then(() => {
      console.log('Seeding completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Seeding failed:', error);
      process.exit(1);
    });
}

module.exports = { seedDatabase };